# Powerline glyphs
set __pm__left_black_arrow_glyph  \uE0B2
set __pm__left_arrow_glyph        \uE0B3
set __pm__vpn_connected_glyph     \uf0ec
set __pm__virtualenv_glyph        \ue606

# Colors
set __pm__node_green 9dfbaa
set __pm__ruby_red   e85951
set __pm_python_blue a7fefd

set __pm__silver   f8f8f0
set __pm__lavender 8076aa
set __pm__pink     ffb8d1

set __pm__dk_grey    333
set __pm__med_grey   999
set __pm__lt_grey    ccc

# Segment color lists
set -g __pm__current_background_color

### Helpers

# Segment list
function __pm_build_segment_list\
  -d "Static list of right segments that have been turned on in settings."

  set -l ruby (if [ $theme_display_ruby ]; true; else; false; end)
  set -l virtualenv (if [ $theme_display_virtualenv ]; true; else; false; end)
  set -l node (if [ $theme_display_node ]; true; else; false; end)
  set -l vpn (if [ $theme_display_vpn ]; true; else; false; end)
  set -l clock (if [ $theme_display_clock ]; true; else; false; end)

  set -g segment_list $ruby $virtualenv $node $clock
end

# Initial context
# [1]: Foreground color hex value.
# [2]: Background color hex value.
# [3]: Number of current segment in segment list.

function __pm_fg_color; $context[1]; end
function __pm_bg_color; $context[2]; end
function __pm_current_segment; $context[3]; end

set -g context NONE NONE 0

function __pm_bind_context\
  -d "Takes a context list and sets prompt variables from it"
  set -l context $argv

  set -g fg $context[1]
  set -g bg $context[2]
  set -g current_segment $context[3]
end

### Segments

__pm_build_segment_list

function __pm__insert_right_separator
  set -l arrow_color $argv[1]
  set -e argv[1]

  if test __pm__current__background_color -eq 'NONE'
    set_color -b normal
    echo -n "$__pm__left_black_arrow_glyph"
    return
  end

  if test -n $__pm__current_background_color
    set_color -b $__pm__current_background_color
  else
    set_color -b normal
  end

  set_color $arrow_color
  echo -n "$__pm__left_black_arrow_glyph"
end

function __pm__start_right_segment -d 'Start a right prompt segment'
  set -l bg $argv[1]
  set -e argv[1]
  set -l fg $argv[1]
  set -e argv[1]

  # Set separator color to the current background
  __pm__insert_right_separator $bg

  set_color -b $bg
  set_color $fg $argv
  echo -n " "

  # Persist colors
  set -g $__pm__current_background_color $bg
  set -g $__pm__current_foreground_color $fg
end

function __pm__finish_right_segments -d 'Close open prompt segments'
  if [ $__pm__current_background_color ]
    if [ $__pm__current_background_color != 'NONE' ]
      set_color $__pm__current_background_color normal
      echo -n "$__pm__left_black_arrow_glyph "
    end
  end

  set_color normal
  set_color -b normal
  set -g $__pm__current_background_color 'NONE'
end

# {{{ start rvm functions
function __pm__rvm_parse_ruby -a ruby_string scope -d 'Parse RVM Ruby string'
  # Function arguments:
  # - 'ruby-2.2.3@rails', 'jruby-1.7.19'...
  # - 'default' or 'current'
  set -l __ruby (echo $ruby_string | cut -d '@' -f 1 2>/dev/null)
  set -g __rvm_{$scope}_ruby_interpreter (echo $__ruby | cut -d '-' -f 1 2>/dev/null)
  set -g __rvm_{$scope}_ruby_version (echo $__ruby | cut -d '-' -f 2 2>/dev/null)
  set -g __rvm_{$scope}_ruby_gemset (echo $ruby_string | cut -d '@' -f 2 2>/dev/null)
  [ "$__ruby_gemset" = "$__ruby" ]; and set -l __ruby_gemset global
end

function __pm__rvm_info -d 'Current Ruby information from RVM'
  # More `sed`/`grep`/`cut` magic...
  set -l __rvm_default_ruby (grep GEM_HOME ~/.rvm/environments/default | \
  sed -e"s/'//g" | sed -e's/.*\///')
  set -l __rvm_current_ruby (rvm-prompt i v g)
  # Parse default and current ruby to global variables
  __pm__rvm_parse_ruby $__rvm_default_ruby default
  __pm__rvm_parse_ruby $__rvm_current_ruby current
  # Show unobtrusive RVM prompt
  if [ "$__rvm_default_ruby" = "$__rvm_current_ruby" ]; return
    # If interpreter differs form default interpreter, show everything:
  else if [ "$__rvm_default_ruby_interpreter" != "$__rvm_current_ruby_interpreter" ]
    if [ "$__rvm_current_ruby_gemset" = 'global' ]; rvm-prompt i v
      else; rvm-prompt i v g; end
        # If version differs form default version
    else if [ "$__rvm_default_ruby_version" != "$__rvm_current_ruby_version" ]
      if [ "$__rvm_current_ruby_gemset" = 'global' ]; rvm-prompt v
      else; rvm-prompt v g; end
      # If gemset differs form default or 'global' gemset, just show it
    else if [ "$__rvm_default_ruby_gemset" != "$__rvm_current_ruby_gemset" ]
    rvm-prompt g;
  end
  set --erase --global __rvm_current_ruby_gemset
  set --erase --global __rvm_current_ruby_interpreter
  set --erase --global __rvm_current_ruby_version
  set --erase --global __rvm_default_ruby_gemset
  set --erase --global __rvm_default_ruby_interpreter
  set --erase --global __rvm_default_ruby_version
end

#}}} end rvm functions

function __pm__show_ruby -d 'Current Ruby (fry/rvm/rbenv)'
  set -l ruby_version

  # Set ruby version from Fry
  if fry >/dev/null 2>&1
    if [ (fry current) = 'system' ]
      set ruby_version "_SYSTEM_RUBY"
    else
      set ruby_version (fry current)
    end

  # Set ruby version from RVM
  else if which rvm-prompt >/dev/null 2>&1
    set ruby_version (__pm__rvm_info)

  # Set ruby version from rbenv
  else if which rbenv >/dev/null 2>&1
    set ruby_version (rbenv version-name)
    # Don't show global ruby version...
    set -q RBENV_ROOT; and set rbenv_root $RBENV_ROOT; or set rbenv_root ~/.rbenv
    [ "$ruby_version" = (cat $rbenv_root/version 2>/dev/null; or echo 'system') ]; and return
  end

  # Display $ruby_version unless it's the system ruby
  if [ $ruby_version != "_SYSTEM_RUBY" ]
    __pm__start_right_segment $__pm__ruby_red $__pm__silver --bold
    echo -n -s ' ' $ruby_version ' '
  end
end

function __pm__prompt_ruby -d 'Display current Ruby information'
  [ "$theme_display_ruby" = 'no' ]; and return
  __pm__show_ruby
end

function __pm__node_following_color
  if [ -n $theme_display_ruby ]
    $__pm__ruby_red
  else
    $__pm__dk_grey
  end
end

function __pm__show_node -d 'Current Node (nvm)'
  set node_version (node --version)

  [ -z "$node_version" ]; and return
  __pm__start_right_segment $__pm__node_green $__pm__dk_grey --bold
  echo -n -s ' ' $node_version ' '
end

function __pm__prompt_vpn -d 'Display current VPN connection status'
  [ "$theme_display_vpn" = 'no' ]; and return
  __pm__show_vpn
end

function __pm__show_vpn -d 'Show the current VPN connection'
  set vpnstatus (scutil --nc show 'Chicago VPN 2' | head -n 1 | awk '{print $2}')

  [ -z "scutil" ]; and return
  if [ "$vpnstatus" = "(Connected)" ]
    __pm__start_right_segment $__pm__pink FFF --bold
    echo -n -s $__pm__vpn_connected_glyph " "
  end
end

function __pm__prompt_node -d 'Display current Node information'
  [ "$theme_display_node" = 'no' ]; and return
  if [ "$default_node" != (node --version) ]
    __pm__show_node
  end
end

function __pm__show_virtualenv -d 'Current Node (nvm)'
  set -l node_version
  set node_version (node --version)

  [ -z "$node_version" ]; and return
  [ "$default_node" = "$node_version" ]; and return

  __pm__start_right_segment $__pm__node_green $__pm__silver --bold
  echo -n -s ' ' $node_version ' '
end

function __pm__prompt_virtualenv -d "Show current Python virtualenv"
  [ "$theme_display_virtualenv" = 'no' ]; and return

  if [ "$VIRTUAL_ENV" ]
    __pm__start_right_segment $__pm_python_blue $__pm__dk_grey --bold
    echo -n -s " " (basename "$VIRTUAL_ENV") " "
  end
end

function __pm__prompt_clock
  [ "$theme_display_clock" = 'no' ]; and return

  set -q theme_date_format; or set -l theme_date_format "+%c"

  __pm__start_right_segment $__pm__lavender $__pm__silver --bold
  date $theme_date_format
  echo " "
end

function __pm_right_segments -d "Coordinate segment order and color"
  __pm__prompt_ruby
  __pm__prompt_node
  __pm__prompt_virtualenv
  __pm__prompt_vpn
  __pm__prompt_clock

end

function fish_right_prompt
  __pm_right_segments
  __pm__finish_right_segments

  # set_color $fish_color_autosuggestion[1]
  # set -q theme_date_format; or set -l theme_date_format "+%c"
  # date $theme_date_format
  set_color normal
  set_color -b normal
  set -g $__pm__current_background_color NONE
end
