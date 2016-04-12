# Github profile message

## Install ##
npm install github-profile-message --save

## Usage ##
Do not use an existed repo or it'll be deleted!

```javascript
gl = require('github-profile-message')({repo: "Your repo name"});
gl.post("message").then(fucntion(){
  // callback
});
```
## Config ##
You can config via construction method or enviroment vars

```
export GITHUB_LED_REPO="Your_repo_name"
export GITHUB_PUSH_NUMBER="Number of commits for each dot." (default is 100)
export GITHUB_LED_FONT="font packeage name" (optional)
```

```javascript
gl = require('github-profile-message')();
gl.config.repo = "repo_name";
gl.config.push_number = 100;
gl.config.font = {"A": [0x7E, 0x11, 0x11, 0x11, 0x7E]}; // package name or object
```
