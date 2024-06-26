#!/bin/bash
# https://www.gitpod.io/docs/configure/user-settings/dotfiles#how-to-install-symlinks-from-dotfiles-when-using-a-custom-installation-script                                                  

current_dir="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"
dotfiles_source="${current_dir}/home_files"

while read -r file; do

    relative_file_path="${file#"${dotfiles_source}"/}"
    target_file="${HOME}/${relative_file_path}"
    target_dir="${target_file%/*}"

    if test ! -d "${target_dir}"; then
        mkdir -p "${target_dir}"
    fi

    printf 'Installing dotfiles symlink %s\n' "${target_file}"
    ln -sf "${file}" "${target_file}"

done < <(find "${dotfiles_source}" -type f)

# Purge webi directories before reinstalling webi             
$(/bin/bash -c 'sudo rm -rf ~/.local/opt ~/.local/*bin* ~/.config/envman/PATH.env')                                         
$(/bin/bash -c 'sudo rm -rf ~/.pyenv ~/.local/share/pyenv')  # WARN: This is to remove pyenv installation following XDG specs.   

# Install webi                                                
curl -sS https://webi.sh/webi | sh                            
                                                              
# Install aliasman via webi                                   
curl -sS https://webi.sh/aliasman | sh                        
                                                              
# Install awless via webi                                     
curl -sS https://webi.sh/awless | sh                          
                                                              
# Install bat via webi                                        
curl -sS https://webi.sh/bat | sh                             
                                                              
# Install brew via webi                                       
# curl -sS https://webi.sh/brew | sh  # brew is installed in gitpod by default                  
                                                              
# Install caddy via webi                                      
curl -sS https://webi.sh/caddy | sh                           
                                                              
# Install curlie via webi                                     
curl -sS https://webi.sh/curlie | sh                          
                                                              
# Install fd-find via webi                                    
curl -sS https://webi.sh/fd | sh                              
                                                              
# no fish installer for linux yet                             
curl -sS https://webi.sh/fish | sh 

# Install fzf via webi                                        
curl -sS https://webi.sh/fzf | sh                             
                                                              
# Install git via webi                                        
curl -sS https://webi.sh/git | sh                             
                                                              
# Install github-cli via webi                                 
curl -sS https://webi.sh/gh | sh                              
                                                              
# Install golang via webi                                     
curl -sS https://webi.sh/golang | sh                          
                                                              
# Install hugo via webi                                       
curl -sS https://webi.sh/hugo | sh                            
                                                              
# no iterm installer for linux                                
curl -sS https://webi.sh/iterm2 | sh     
                                                            
# Install jq via webi                                         
curl -sS https://webi.sh/jq | sh                              
                                                              
# install node.js (for github copilot)                        
curl -sS https://webi.sh/node | sh                                             
                                                              
# install powershell                                          
curl -sS https://webi.sh/pwsh | sh                            
                                                              
# install pathman                                             
curl -sS https://webi.sh/pathman | sh                         
                                                              
# install pyenv (conflict free python install)                
curl -sS https://webi.sh/pyenv | sh                           
                                                              
# ensure correct pyenv path is exported by pathman            
pathman add "$HOME/.local/share/pyenv/bin"                    
pathman add "$HOME/.local/share/pyenv/shims"                  
                                                              
# path declaration in fish is kept default. addtional paths are added via pathman.               
pathman add "/opt/bin"                                        
pathman add "$HOME/.local/share/go/bin"                       
                                                              
# Install rg via webi                                         
curl -sS https://webi.sh/rg | sh                              
                                                              
# install rustlang via webi                                   
curl -sS https://webi.sh/rustlang | sh                        
                                                              
# Install serviceman via webi                                 
curl -sS https://webi.sh/serviceman | sh                      
                                                              
# Install zig via webi                                        
curl -sS https://webi.sh/zig | sh                             
                                                              
# not really from webi but also installs by piping into sh    
curl -sS https://starship.rs/install.sh | sh                  
                                                              
# Ensure this command is always at the end of all webi installations.                                                       
# Update paths when after webi installations (bash)           
/bin/bash -c "source ~/.config/envman/PATH.env"               
                                                              
# Update paths when after webi installations (fish)           
# /usr/bin/fish -c "source ~/.config/envman/PATH.env"  

directory = "~/.local/share/fonts"

# download JetBrains fonts, and extract to fonts directory
curl https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip

if [ -d "$directory" ]; then
    echo "Directory exists."
else
    echo "Directory does not exist. Running command..."
    # Replace the command below with the command you want to run
    mkdir -p "$directory"  # This command creates the directory if it doesn't exist
    # Example command: mkdir -p "$directory"
fi

unzip JetBrainsMono.zip -d $directory

# install tmux and plugin manager
sudo apt update && sudo apt install tmux gcc g++ -y
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Setup git completions for bash
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash
echo "source ~/.git-completion.bash" >> ~/.bashrc


# install helix
git clone https://github.com/helix-editor/helix
# cd helix
# cargo install --path helix-term --locked
# cp -r $HOME/helix/runtime .
