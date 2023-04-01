# use command
export PROJECTS_ROOT=~/Projects
DEFAULT_IDE="code ."
use () {
  # TODO: Add autocomplete support for this in at least zsh and bash. So it will pull from whatever "projects()" returns to use for the project name.
  local PROJECT_NAME=$1
  cd "$PROJECTS_ROOT/$PROJECT_NAME"
  # Add local node modules to path
  if [ -d "$PWD/node_modules/.bin:$PATH" ]; then
    export PATH="$PWD/node_modules/.bin:$PATH"
  fi
  # Switch to the project's version of node
  if [ -f ./.nvmrc ]; then
    # TODO: install the requested version if it doesn't exist
    nvm use `cat ./.nvmrc`
  fi
  # Run the project specific commands
  # TODO: add a general version of this like .shrc and one for the other shell style. csh maybe.
  if [ -f "./.zshrc" -a "$ZSH_VERSION" ]; then
    source .zshrc
  elif [ -f "./.bashrc" -a "$BASH_VERSION" ]; then
    source .bashrc
  fi
  local XCODE_WORKSPACES="$(compgen -G "*.xcworkspace")"
  export XCODE_PROJECTS="$(compgen -G "*.xcodeproj")"
  # TODO: Add a --no-ide switch to not open an ide when using a project
  # TODO: Add a variable that can be set in the project .zshrc or .bashrc file to not detect and run an editor. i.e. .zshrc runs qb64 and then sets some variable to 1 to disable these checks to launch a different editor.
  if [ -d ./.vscode ]; then
    # VS Code
    code .
  elif [ -n "$XCODE_WORKSPACES" ]; then
    while IFS= read -r line; do 
      open "$line"
    done <<< "$XCODE_PROJECTS"
  elif [ -n "$XCODE_PROJECTS" ]; then
    while IFS= read -r line; do 
      open "$line"
    done <<< "$XCODE_PROJECTS"
  elif [ -f ./.idea/misc.xml ]; then
    # Is misc.xml the right file to check for? Maybe just the .idea directory existing and being a directory.
    # So still use the project type from misc.xml to decide which intellij ide to load, but stop checking for other IDEs if .idea exists.
    # IntelliJ projects
    local INTELLIJ_PROJECT_TYPE=$(xpath -q -e 'string(/project/component[@name="ProjectType"]/option[@name="id"]/@value)' .idea/misc.xml)
    if [ "Android" = "$INTELLIJ_PROJECT_TYPE" ]; then
    # Android Studio
      open -a /Applications/Android\ Studio.app .
    else
      echo $INTELLIJ_PROJECT_TYPE
      echo "TODO: launch intellij or whatever IDE"
      eval $DEFAULT_IDE
    fi
  else
    # Unrecognized project type
    echo "Is not a project"
    eval $DEFAULT_IDE
  fi
}

projects () {
  find "$PROJECTS_ROOT" -maxdepth 1 -type d -exec basename {} \; | sort
}

new_project() {
    PROJECT_DIR=$PROJECTS_ROOT/$1
    mkdir -p "$PROJECT_DIR"
    touch "$PROJECT_DIR/.project.sh"
    touch "$PROJECT_DIR/README.md"
    if [ ! -d "$PROJECT_DIR/.git" ]; then
        git init "$PROJECT_DIR"
    fi
    cd "$PROJECT_DIR"
}
