#!/usr/bin/env bats

#header testing
@test "Header - Colortesting 1" {
  color="$(. src/wslu-header.sh;echo -e $black | cat -A)"
  [ "$color" = "^[[30m$" ]
}

@test "Header - Colortesting 2" {
  color="$(. src/wslu-header.sh;echo -e $light_red | cat -A)"
  [ "$color" = "^[[1;31m$" ]
}

@test "Header - colortesting 3" {
  color="$(. src/wslu-header.sh;echo -e $orange | cat -A)"
  [ "$color" = "^[[38;5;202m$" ]
}

@test "Header - Format 1" {
  format="$(. src/wslu-header.sh;echo -e $bold | cat -A)"
  [ "$format" = "^[[1m$" ]
}

@test "Header - Format 2" {
  format="$(. src/wslu-header.sh;echo -e $reset | cat -A)"
  [ "$format" = "^[(B^[[m$" ]
}

@test "Header - Indicator" {
  format="$(. src/wslu-header.sh;echo -e $info | cat -A)"
  [ "$format" = "^[[32m[info]^[(B^[[m$" ]
}

@test "Header - Double Dash Parsing" {
  format="$(. src/wslu-header.sh; echo "$(double_dash_p "\\")")"
  [ "$format" = "\\\\" ]
}

@test "Header - Interop Prefix" {
  format="$(. src/wslu-header.sh; echo "$(interop_prefix)")"
  [ "$format" = "/mnt/" ]
}

@test "Header - System Drive Prefix" {
  format="$(. src/wslu-header.sh; echo "$(sysdrive_prefix)")"
  [ "$format" = "c" ]
}