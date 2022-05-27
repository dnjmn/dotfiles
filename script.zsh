mkdir -p ~/Github/$USER/private


# TODO: check if git installed
# INSTALLING GIT
# if ! type git > /dev/null; then
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
     sudo apt-get install git
  elif [[ "$OSTYPE" == "darwin"* ]]; then
      # xcode command line tools
     xcode-select --install
  fi
# fi


# mac only
# defaults write -g InitialKeyRepeat -int 10

git clone git@github.com:dnjmn/dotfiles.git ~/Github/$USER/private/dotfiles
# change repo ref to com-dnjmn
# zsh ~/Github/$USER/private/dotfiles/script.zsh
#git@github.com:dnjmn/nvim.git

