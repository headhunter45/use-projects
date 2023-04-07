# use command
export PROJECTS_ROOT=~/Projects
DEFAULT_IDE="code ."
use () {
  # TODO: Add autocomplete support for this in at least zsh and bash. So it will pull from whatever "projects()" returns to use for the project name.
  # TODO: Consider replacing/augmenting .shrc with some sort of .project file. Mostly to override project type detection.
  local PROJECT_NAME=$1
  if [ -z "$PROJECTS_ROOT" ]; then
    echo "PROJECTS_ROOT not set."
  elif [ -z "$PROJECT_NAME" ]; then
    echo "PROJECT_NAME not specified."
  elif [ ! -d "$PROJECTS_ROOT/$PROJECT_NAME" ]; then
    echo "Project ${PROJECT_NAME} does not exist in ${PROJECTS_ROOT}."
  else
    cd "$PROJECTS_ROOT/$PROJECT_NAME"
    # Add local node modules to path
    if [ -d "$PWD/node_modules/.bin" ]; then
      export PATH="$PWD/node_modules/.bin:$PATH"
    fi
    # Switch to the project's version of node
    if [ -f .nvmrc ]; then
      nvm use 2>/dev/null || nvm install
    fi
    # Run the project specific commands
    # TODO: add a general version of this like .shrc and one for the other shell style. csh maybe.
    # TODO: Maybe separate these. BASH_VERSION and ZSH_VERSION should never be srt at the same time, but we may want .bashrc and .shrc to both be executed if present and running under bash.
    if [ -f .bashrc -a -n "$BASH_VERSION" ]; then
      source .bashrc
    elif [ -f .zshrc -a -n "$ZSH_VERSION" ]; then
      source .zshrc
    elif [ -f .shrc ]; then
      source .shrc
    fi

    local XCODE_WORKSPACES="$(compgen -G "*.xcworkspace")"
    local XCODE_PROJECTS="$(compgen -G "*.xcodeproj")"
    # TODO: Add a --no-ide switch to not open an ide when using a project.
    # TODO: Add a variable that can be set in the project .zshrc or .bashrc file to not detect and run an editor. i.e. .zshrc runs qb64 and then sets some variable to 1 to disable these checks to launch a different editor.
    if [ -d .vscode ]; then
      # VS Code settings found
      code . >/dev/null 2>&1 &
    elif [ -n "$XCODE_WORKSPACES" ]; then
      # XCode workspace found
      while IFS= read -r line; do
        open "$line" >/dev/null 2>&1 &
      done <<< "$XCODE_WORKSPACES"
    elif [ -n "$XCODE_PROJECTS" ]; then
      # XCode project found
      while IFS= read -r line; do
        open "$line" >/dev/null 2>&1 &
      done <<< "$XCODE_PROJECTS"
    elif [ -f .idea/misc.xml ]; then
      # IntelliJ project found
      # Is misc.xml the right file to check for? Maybe just the .idea directory existing and being a directory.
      # So still use the project type from misc.xml to decide which intellij ide to load, but stop checking for other IDEs if .idea exists.
      # IntelliJ projects
      local INTELLIJ_PROJECT_TYPE=$(xpath -q -e 'string(/project/component[@name="ProjectType"]/option[@name="id"]/@value)' .idea/misc.xml)
      if [ "Android" = "$INTELLIJ_PROJECT_TYPE" ]; then
        # Android Studio project found
        # TODO: Make this work for linux is it studio.sh? What is it under WSL or git bash?
        open -a /Applications/Android\ Studio.app . >/dev/null 2>&1 &
      else
        # By default IntelliJ projects don't have a project type so all others should open with IntelliJ
        echo $INTELLIJ_PROJECT_TYPE
        if [ -d /Applications/IntelliJ.app ]; then
          open /Applications/IntelliJ.app . >/dev/null 2>&1 &
        elif [ command -v idea64 ]; then
          idea64 . >/dev/null 2>&1 &
        else
          # We can't find IntelliJ so just launch the default IDE
          eval $DEFAULT_IDE >/dev/null 2>&1 &
        fi
      fi
    else
      # TODO: Detect qb64 apps. Workaround is to open the main .bas file in qb64 from .shrc.
      # TODO: Detect vb6 apps.
      # TODO: Detect vc6/vc++6 apps.
      # TODO: Detect other visual studio solution/project files.
      # TODO: Maybe detect MSBuild projects and try to open visual studio/visual studio mac.
      # TODO: Detect other editors config/project files. 
      # TODO: Detect plain java apps. 

      # Unrecognized project type
      echo "This is not a recognized project type."
      eval $DEFAULT_IDE
    fi
  fi
}

projects () {
  find "$PROJECTS_ROOT" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
}

new_project() {
    PROJECT_DIR=$PROJECTS_ROOT/$1
    mkdir -p "$PROJECT_DIR"
    touch "$PROJECT_DIR/.project.sh"
    touch "$PROJECT_DIR/README.md"
    echo ".gitattributes" > "$PROJECT_DIR/.gitignore"
    echo ".vscode" > "$PROJECT_DIR/.gitignore"
    echo "build" > "$PROJECT_DIR/.gitignore"
    echo "tmp" > "$PROJECT_DIR/.gitignore"
    touch "$PROJECT_DIR/.gitattributes"
    if [ ! -d "$PROJECT_DIR/.git" ]; then
        git init "$PROJECT_DIR"
    fi
    cd "$PROJECT_DIR"
    git add --all .
    git commit -m "Initial commit."
}

clone() {
  if [ -z "$1" -o "$1" = " " -o -z "$2" -o "$2" = " " ]; then
    echo "Clones the repo into \$PROJECTS_ROOT/<projectName>"
    echo "usage: clone <repositoryUrl> <projectName>"
    return
  fi

  # TODO: Also check if $PROJECTS_ROOT/$2 already exists.
  
  git clone "$1" "$PROJECTS_ROOT/$2" && use "$2"
}
