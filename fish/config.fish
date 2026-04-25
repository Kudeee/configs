source /usr/share/cachyos-fish-config/cachyos-config.fish

set --universal nvm_default_version lts # or whatever version you use

set -gx EDITOR nvim

printf "\e[2 q"

# overwrite greeting
# potentially disabling fastfetch
function fish_greeting
    fastfetch
end
#    # smth smth
#end
