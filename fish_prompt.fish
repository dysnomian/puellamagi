# name: puellamagi
#
# puellamagi is a Powerline-style, Git-aware fish theme optimized for awesome, essentially stolen from bobthefish.
#
# You will need a Powerline-patched font for this to work:
#
#     https://powerline.readthedocs.org/en/latest/fontpatching.html
#
# I recommend picking one of these:
#
#     https://github.com/Lokaltog/powerline-fonts
#
# You can override some default prompt options in your config.fish:
#
#     set -g theme_display_git no
#     set -g theme_display_git_untracked no
#     set -g theme_display_git_ahead_verbose yes
#     set -g theme_display_hg yes
#     set -g theme_display_virtualenv no
#     set -g theme_display_ruby no
#     set -g theme_display_user yes
#     set -g theme_display_vi yes
#     set -g theme_display_vi_hide_mode default
#     set -g theme_avoid_ambiguous_glyphs yes
#     set -g default_user your_normal_user

set -g __ff_current_background_color NONE

# Powerline glyphs
set __puellamagi_branch_glyph            \uE0A0
set __puellamagi_ln_glyph                \uE0A1
set __puellamagi_padlock_glyph           \uE0A2
set __puellamagi_right_black_arrow_glyph \uE0B0
set __puellamagi_right_arrow_glyph       \uE0B1
set __puellamagi_left_black_arrow_glyph  \uE0B2
set __puellamagi_left_arrow_glyph        \uE0B3

# Additional glyphs
set __puellamagi_detached_glyph          \u27A6
set __puellamagi_nonzero_exit_glyph      '! '
set __puellamagi_superuser_glyph         '$ '
set __puellamagi_bg_job_glyph            '% '
set __puellamagi_hg_glyph                \u263F

# Python glyphs
set __puellamagi_superscript_glyph       \u00B9 \u00B2 \u00B3
set __puellamagi_virtualenv_glyph        \u25F0
set __puellamagi_pypy_glyph              \u1D56

# Colors
set __puellamagi_silver        #f8f8f0
set __puellamagi_dark_gray     #49483e
set __puellamagi_lavender_gray #5a5475
set __puellamagi_shadow        #3b3a32
set __puellamagi_bg_purple     #5a5475

set __puellamagi_pink         #ffb8d1
set __puellamagi_peach        #ff857f
set __puellamagi_magenta      #f92672
set __puellamagi_deep_magenta #c7054c

set __puellamagi_pale_gold #fffbe6
set __puellamagi_goldenrod #fffea0
set __puellamagi_gold      #e6c000
set __puellamagi_deep_gold #b39500

set __puellamagi_pale_seafoam #e6fff2
set __puellamagi_seafoam      #c2ffdf
set __puellamagi_dark_seafoam #80ffbd

set __puellamagi_dusty_lilac   #efe6ff
set __puellamagi_lilac         #c5a3ff
set __puellamagi_lavender      #8076aa
set __puellamagi_bright_purple #ae81ff
set __puellamagi_violet        #63588d

# ===========================
# Helper methods
# ===========================

# function __puellamagi_in_git -d 'Check whether pwd is inside a git repo'
#   command which git > /dev/null 2>&1; and command git rev-parse --is-inside-work-tree >/dev/null 2>&1
# end

# function __puellamagi_in_hg -d 'Check whether pwd is inside a hg repo'
#   command which hg > /dev/null 2>&1; and command hg stat > /dev/null 2>&1
# end

function __puellamagi_git_branch -d 'Get the current git branch (or commitish)'
  set -l ref (command git symbolic-ref HEAD ^/dev/null)
  if [ $status -gt 0 ]
    set -l branch (command git show-ref --head -s --abbrev | head -n1 ^/dev/null)
    set ref "$__puellamagi_detached_glyph $branch"
  end
  echo $ref | sed  "s#refs/heads/#$__puellamagi_branch_glyph #"
end

function __puellamagi_hg_branch -d 'Get the current hg branch'
  set -l branch (command hg branch ^/dev/null)
  set -l book (command hg book | grep \* | cut -d\  -f3)
  echo "$__puellamagi_branch_glyph $branch @ $book"
end

function __puellamagi_pretty_parent -a current_dir -d 'Print a parent directory, shortened to fit the prompt'
  echo -n (dirname $current_dir) | sed -e 's#/private##' -e "s#^$HOME#~#" -e 's#/\(\.\{0,1\}[^/]\)\([^/]*\)#/\1#g' -e 's#/$##'
end

function __puellamagi_git_project_dir -d 'Print the current git project base directory'
  [ "$theme_display_git" = 'no' ]; and return
  command git rev-parse --show-toplevel ^/dev/null
end

function __puellamagi_hg_project_dir -d 'Print the current hg project base directory'
  [ "$theme_display_hg" = 'yes' ]; or return
  set d (pwd)
  while not [ $d = / ]
    if [ -e $d/.hg ]
      command hg root --cwd "$d" ^/dev/null
      return
    end
    set d (dirname $d)
  end
end

function __puellamagi_project_pwd -a current_dir -d 'Print the working directory relative to project root'
  echo "$PWD" | sed -e "s#$current_dir##g" -e 's#^/##'
end

function __puellamagi_git_ahead -d 'Print the ahead/behind state for the current branch'
  if [ "$theme_display_git_ahead_verbose" = 'yes' ]
    __puellamagi_git_ahead_verbose
    return
  end

  command git rev-list --left-right '@{upstream}...HEAD' ^/dev/null | awk '/>/ {a += 1} /</ {b += 1} {if (a > 0 && b > 0) nextfile} END {if (a > 0 && b > 0) print "±"; else if (a > 0) print "+"; else if (b > 0) print "-"}'
end

function __puellamagi_git_ahead_verbose -d 'Print a more verbose ahead/behind state for the current branch'
  set -l commits (command git rev-list --left-right '@{upstream}...HEAD' ^/dev/null)
  if [ $status != 0 ]
    return
  end

  set -l behind (count (for arg in $commits; echo $arg; end | grep '^<'))
  set -l ahead (count (for arg in $commits; echo $arg; end | grep -v '^<'))

  switch "$ahead $behind"
    case '' # no upstream
    case '0 0' # equal to upstream
      return
    case '* 0' # ahead of upstream
      echo "↑$ahead"
    case '0 *' # behind upstream
      echo "↓$behind"
    case '*' # diverged from upstream
      echo "↑$ahead↓$behind"
  end
end

# ===========================
# Segment functions
# ===========================

function __puellamagi_start_segment -d 'Start a prompt segment'
  set -l bg $argv[1]
  set -e argv[1]
  set -l fg $argv[1]
  set -e argv[1]

  set_color normal # clear out anything bold or underline...
  set_color -b $bg
  set_color $fg $argv
  if [ "$__ff_current_background_color" = 'NONE' ]
    # If there's no background, just start one
    echo -n ' '
  else
    # If there's already a background...
    if [ "$bg" = "$__ff_current_background_color" ]
    # and it's the same color, draw a separator
      echo -n "$__puellamagi_right_arrow_glyph "
    else
      # otherwise, draw the end of the previous segment and the start of the next
      set_color $__ff_current_background_color
      echo -n "$__puellamagi_right_black_arrow_glyph "
      set_color $fg $argv
    end
  end
  set __ff_current_background_color $bg
end

function __puellamagi_path_segment -a current_dir -d 'Display a shortened form of a directory'
  if [ -w "$current_dir" ]
    __puellamagi_start_segment $__puellamagi_lavender $__puellamagi_silver
  else
    __puellamagi_start_segment $__puellamagi_magenta $__puellamagi_silver
  end

  set -l directory
  set -l parent

  switch "$current_dir"
    case /
      set directory '/'
    case "$HOME"
      set directory '~'
    case '*'
      set parent    (__puellamagi_pretty_parent "$current_dir")
      set parent    "$parent/"
      set directory (basename "$current_dir")
  end

  [ "$parent" ]; and echo -n -s "$parent"
  set_color fff --bold
  echo -n "$directory "
  set_color normal
end

function __puellamagi_finish_segments -d 'Close open prompt segments'
  if [ -n $__ff_current_background_color -a $__ff_current_background_color != 'NONE' ]
    set_color -b normal
    set_color $__ff_current_background_color
    echo -n "$__puellamagi_right_black_arrow_glyph "
    set_color normal
  end
  set -g __ff_current_background_color NONE
end


# ===========================
# Theme components
# ===========================

function __puellamagi_prompt_status -d 'Display symbols for a non zero exit status, root and background jobs'
  set -l nonzero
  set -l superuser
  set -l bg_jobs

  # Last exit was nonzero
  if [ $status -ne 0 ]
    set nonzero $__puellamagi_nonzero_exit_glyph
  end

  # if superuser (uid == 0)
  if [ (id -u $USER) -eq 0 ]
    set superuser $__puellamagi_superuser_glyph
  end

  # Jobs display
  if [ (jobs -l | wc -l) -gt 0 ]
    set bg_jobs $__puellamagi_bg_job_glyph
  end

  if [ "$nonzero" -o "$superuser" -o "$bg_jobs" ]
    __puellamagi_start_segment fff 000
    if [ "$nonzero" ]
      set_color $__puellamagi_magenta --bold
      echo -n $__puellamagi_nonzero_exit_glyph
    end

    if [ "$superuser" ]
      set_color $__puellamagi_gold --bold
      echo -n $__puellamagi_superuser_glyph
    end

    if [ "$bg_jobs" ]
      set_color $__puellamagi_seafoam --bold
      echo -n $__puellamagi_bg_job_glyph
    end

    set_color normal
  end
end

function __puellamagi_prompt_user -d 'Display actual user if different from $default_user'
  if [ "$theme_display_user" = 'yes' ]
    if [ "$USER" != "$default_user" -o -n "$SSH_CLIENT" ]
      __puellamagi_start_segment $__puellamagi_seafoam $__puellamagi_bg_purple
      echo -n -s (whoami) '@' (hostname | cut -d . -f 1) ' '
    end
  end
end

function __puellamagi_prompt_hg -a current_dir -d 'Display the actual hg state'
  set -l dirty (command hg stat; or echo -n '*')

  set -l flags "$dirty"
  [ "$flags" ]; and set flags ""

  set -l flag_bg $__puellamagi_seafoam
  set -l flag_fg $__puellamagi_bg_purple
  if [ "$dirty" ]
    set flag_bg $__puellamagi_magenta
    set flag_fg fff
  end

  __puellamagi_path_segment $current_dir

  __puellamagi_start_segment $flag_bg $flag_fg
  echo -n -s $__puellamagi_hg_glyph ' '

  __puellamagi_start_segment $flag_bg $flag_fg --bold
  echo -n -s (__puellamagi_hg_branch) $flags ' '
  set_color normal

  set -l project_pwd  (__puellamagi_project_pwd $current_dir)
  if [ "$project_pwd" ]
    if [ -w "$PWD" ]
      __puellamagi_start_segment 333 999
    else
      __puellamagi_start_segment $__puellamagi_magenta $__puellamagi_silver
    end

    echo -n -s $project_pwd ' '
  end
end

function __puellamagi_prompt_git -a current_dir -d 'Display the actual git state'
  set -l dirty   (command git diff --no-ext-diff --quiet --exit-code; or echo -n '*')
  set -l staged  (command git diff --cached --no-ext-diff --quiet --exit-code; or echo -n '~')
  set -l stashed (command git rev-parse --verify --quiet refs/stash >/dev/null; and echo -n '$')
  set -l ahead   (__puellamagi_git_ahead)

  set -l new ''
  set -l show_untracked (git config --bool bash.showUntrackedFiles)
  if [ "$theme_display_git_untracked" != 'no' -a "$show_untracked" != 'false' ]
    set new (command git ls-files --other --exclude-standard --directory --no-empty-directory)
    if [ "$new" ]
      if [ "$theme_avoid_ambiguous_glyphs" = 'yes' ]
        set new '...'
      else
        set new '…'
      end
    end
  end

  set -l flags "$dirty$staged$stashed$ahead$new"
  [ "$flags" ]; and set flags " $flags"

  set -l flag_bg $__puellamagi_seafoam
  set -l flag_fg $__puellamagi_bg_purple
  if [ "$dirty" -o "$staged" ]
    set flag_bg $__puellamagi_magenta
    set flag_fg $__puellamagi_silver
  else if [ "$stashed" ]
    set flag_bg $__puellamagi_gold
    set flag_fg $__puellamagi_pale_goldenrod
  end
  
  __puellamagi_path_segment $current_dir
  
  __puellamagi_start_segment $flag_bg $flag_fg --bold
  echo -n -s (__puellamagi_git_branch) $flags ' '
  set_color normal

  set -l project_pwd (__puellamagi_project_pwd $current_dir)
  if [ "$project_pwd" ]
    if [ -w "$PWD" ]
      __puellamagi_start_segment 333 999
    else
      __puellamagi_start_segment $__puellamagi_magenta $__puellamagi_silver
    end

    echo -n -s $project_pwd ' '
  end
end

function __puellamagi_prompt_dir -d 'Display a shortened form of the current directory'
  __puellamagi_path_segment "$PWD"
end

function __puellamagi_prompt_vi -d 'Display vi mode'
  [ "$theme_display_vi" = 'yes' -a "$fish_bind_mode" != "$theme_display_vi_hide_mode" ]; or return
  switch $fish_bind_mode
  case default
    __puellamagi_start_segment $__puellamagi_bg_purple $__puellamagi_silver --bold
    echo -n -s 'N '
  case insert
    __puellamagi_start_segment $__puellamagi_pale_seafoam $__puellamagi_lavender_gray --bold
    echo -n -s 'I '
  case visual
    __puellamagi_start_segment $__puellamagi_pale_goldenrod $__puellamagi_deep_gold --bold
    echo -n -s 'V '
  end
  set_color normal
end

function __puellamagi_virtualenv_python_version -d 'Get current python version'
  set -l python_version (readlink (which python))
  switch "$python_version"
  case 'python2*'
    echo $__puellamagi_superscript_glyph[2]
  case 'python3*'
    echo $__puellamagi_superscript_glyph[3]
  case 'pypy*'
    echo $__puellamagi_pypy_glyph
  end
end

function __puellamagi_prompt_virtualfish -d "Display activated virtual environment (only for virtualfish, virtualenv's activate.fish changes prompt by itself)"
  [ "$theme_display_virtualenv" = 'no' -o -z "$VIRTUAL_ENV" ]; and return
  set -l version_glyph (__puellamagi_virtualenv_python_version)
  if [ "$version_glyph" ]
    __puellamagi_start_segment $__puellamagi_seafoam $__puellamagi_silver
    echo -n -s $__puellamagi_virtualenv_glyph $version_glyph
  end
  __puellamagi_start_segment $__puellamagi_seafoam $__puellamagi_silver --bold
  echo -n -s (basename "$VIRTUAL_ENV") ' '
  set_color normal
end

# ===========================
# Apply theme
# ===========================

function fish_prompt -d 'puellamagi, a fish theme optimized for Liss'
  __puellamagi_prompt_status
  __puellamagi_prompt_vi
  __puellamagi_prompt_user

  set -l git_root (__puellamagi_git_project_dir)
  set -l hg_root  (__puellamagi_hg_project_dir)
  if [ (echo "$hg_root" | wc -c) -gt (echo "$git_root" | wc -c) ]
    __puellamagi_prompt_hg $hg_root
  else if [ "$git_root" ]
    __puellamagi_prompt_git $git_root
  else
    __puellamagi_prompt_dir
  end

  __puellamagi_finish_segments
end
