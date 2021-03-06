nodegit = require "nodegit"
path = require "path"
promisify = require "promisify-node"
github = require "githubot"
temp = promisify require("temp").track()
fse = promisify require "fs-extra"

class GithubLED
  constructor: (config={}) ->
    @config =
      repo: config.repo || process.env.GITHUB_LED_REPO
      push_number: config.push_number || process.env.GITHUB_PUSH_NUMBER || 100
    if config.font?
      if typeof config.font is "string"
        @config.font = require config.font
      else
        @config.font = config.font
    else
      @config.font = require process.env.GITHUB_LED_FONT || "./font"
    @font = @config.font
    throw "Repo is not defined" unless @config.repo?

  verify_message: (message) ->
    errors = []
    errors.push "Message length should not exceed 8 characters." if message.length > 8
    for index, character of message
      errors.push "Character #{character} can't be displayed." unless @font[character]?
    if errors.length > 0 then errors else null

  commits: (time) ->
    [0...@config.push_number].reduce (p) =>
      p.then () => @commit time
    , Promise.resolve()

  commit: (time) ->
    @repository.index().then (idx) =>
      @index = idx
    .then () =>
      @index.addByPath "README.md"
    .then () =>
      @index.write()
    .then () =>
      @index.writeTree()
    .then (oid) =>
      author = nodegit.Signature.create @name, @email, time, 0
      committer = nodegit.Signature.create @name, @email, time, 0

      if @parent
        @repository.createCommit "HEAD", author, committer, "message", oid, [@parent]
      else
        @repository.createCommit "HEAD", author, committer, "message", oid
    .then (@parent) =>

  post: (raw_text) ->
    # preprocess text
    text = []
    for index, character of raw_text
      text = text.concat @font[character]
      text.push 0x00

    # get root date
    date = new Date
    date.setFullYear date.getFullYear()-1
    date.setMonth date.getMonth()+1
    date.setDate 1
    date.setDate 8-date.getDay()

    # create LED matrix
    matrix = []
    for row in text
      for i in [0...7]
        p = 1 << i
        matrix.push date.getTime()/1000 if p & row
        date.setDate date.getDate()+1

    # create git repo
    github.get("user").then (user) =>
      @name = user.name
      @email = user.email
      @user = user.login
      @git = user.html_url.replace
      if @email?
        Promise.resolve()
      else
        github.get("user/emails").then (emails) =>
          @email = emails[0].email
    .then () =>
      temp.mkdir "git_folder"
    .then (dir_path) =>
      nodegit.Repository.init dir_path, 0
    .then (@repository) =>
      fse.writeFile path.join(@repository.workdir(), "README.md"), "# Nothing here"
    .then () =>
      matrix.reduce (p, time) =>
        p.then () => @commits time
      , Promise.resolve()
    .then () =>
      github.get "user/repos"
    .then (repos) =>
      url = null
      for repo in repos
        url = repo.url if repo.name == @config.repo and repo.owner.login == @user
      if url? then github.delete url else Promise.resolve()
    .then () =>
      github.post "user/repos", name: @config.repo
    .then (repo) =>
      nodegit.Remote.create @repository, "origin", repo.clone_url
    .then (remote) =>
      remote.push ["refs/heads/master:refs/heads/master"], callbacks:
        certificateCheck: () -> 1
        credentials: (url, userName) ->
          nodegit.Cred.userpassPlaintextNew process.env.HUBOT_GITHUB_TOKEN, "x-oauth-basic"
    .then () =>
      temp.cleanup()
    .catch (err) =>
      console.log err

module.exports = GithubLED
