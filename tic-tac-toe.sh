#!/bin/bash

set -r board

MAX_LEVEL=5

NONE=0
WE=1
OPPONENT=-1

WE_WIN=1
OPPONENT_WINS=-1
DRAW=0
NOT_OVER=2

check_result() {
   b=("$@")
   
   logger -p error "b[0]=${b[0]}"
   if [ \( ${b[0]} -eq ${b[1]} \)  -a \( ${b[1]} -eq ${b[2]} \) -a \( ${b[0]} -ne $NONE \) ] ; then echo ${b[0]};
   elif [ \( ${b[0]} -eq ${b[3]} \)  -a \( ${b[3]} -eq ${b[6]} \) -a \( ${b[0]} -ne $NONE \) ] ; then echo ${b[0]};
   elif [ \( ${b[6]} -eq ${b[7]} \)  -a \( ${b[7]} -eq ${b[8]} \) -a \( ${b[6]} -ne $NONE \) ] ; then echo ${b[6]}; 
   elif [ \( ${b[2]} -eq ${b[5]} \)  -a \( ${b[5]} -eq ${b[8]} \) -a \( ${b[2]} -ne $NONE \) ] ; then echo ${b[2]};

   elif [ \( ${b[0]} -eq ${b[4]} \)  -a \( ${b[4]} -eq ${b[8]} \) -a \( ${b[0]} -ne $NONE \) ] ; then echo ${b[4]};
   elif [ \( ${b[1]} -eq ${b[4]} \)  -a \( ${b[4]} -eq ${b[7]} \) -a \( ${b[1]} -ne $NONE \) ] ; then echo ${b[4]};
   elif [ \( ${b[2]} -eq ${b[4]} \)  -a \( ${b[4]} -eq ${b[6]} \) -a \( ${b[2]} -ne $NONE \) ] ; then echo ${b[4]};
   elif [ \( ${b[5]} -eq ${b[4]} \)  -a \( ${b[4]} -eq ${b[3]} \) -a \( ${b[5]} -ne $NONE \) ] ; then echo ${b[4]};
  
   else 
     result=$DRAW;
     for c in "${b[@]}"; do
        if [ $c -eq $NONE ]; then
           result=$NOT_OVER;
           break;
        fi
     done
     echo $result;
   fi
}

log_board() {
  b=("$@")
  s=""
  for c in "${b[@]}"; do
    s="$s $c";
  done
  echo "$s" >&2
}

print_board() {
  local i
  local b
  local c

  b=("$@")
  
  i=0
  for c in "${b[@]}"; do
        if [ $c -eq $WE ]; then
          printf " o ";
        elif [ $c -eq $OPPONENT ]; then
          printf " X ";
        else 
          printf " $i ";
        fi
        i=$(($i+1));
        if [ $(($i  % 3)) -eq 0 ]; then
           printf "\n"
        else 
           printf "|"
        fi
  done
}

get_opponent() {
   if [ $1 -eq $WE ]; then
      echo $OPPONENT;
   else 
      echo $WE;
   fi
}

# args: player - WE or OPPONENT
#       rec_level
#       board  
calc_move() {
   local i
   local b
   local bm
   local cm
   local mscore
   local score
   local pl
   local level
   local l

   pl=$1
   shift
   level=$1
   shift
   b=("$@")

   echo "working on board" >&2
   print_board "${b[@]}" >&2
   echo "level=$level" >&2

   move=-1
   score=-2
   if [ $pl -eq $OPPONENT ]; then
     score=-2
   else
     score=2
   fi

   r=`check_result ${b[@]}`
   opponent=`get_opponent $pl`
   echo "player=$pl opponent=$opponent" >&2
   if [ $r -eq $WE ]; then
      echo "1";
      echo "returned 1" >&2
      return;
   elif [ $r -eq $OPPONENT ]; then
      echo "-1";
      echo "returned -1" >&2
      return;
   fi

   for ((i=0; i<"${#b[@]}"; i=$i+1)); do
      if  [ ${b[$i]} -eq $NONE ]; then
          bm=("${b[@]}")
          bm[$i]=$pl
          
          echo "b[$i]=${b[$i]}" >&2
          l=$((level+1))
          echo "move=$i l=$l">&2
          if [ $l -lt $MAX_LEVEL ]; then
            cm=`calc_move $opponent $l ${bm[@]} | cut -d \; -f 1 `
            echo "Returned to board, checking move $i ">&2
            print_board "${b[@]}" >&2
            
            #mscore=$((-$cm))
            mscore=$(($cm))
          else 
            mscore=0
          fi
          echo "move=$i score=$mscore">&2
          if [ $pl -eq $OPPONENT ]; then
            if [ $mscore -gt  $score ]; then
               score=$mscore;
               move=$i
            fi
          else
            if [ $mscore -lt  $score ]; then
               score=$mscore;
               move=$i
            fi
          fi
      fi
   done

   if [ $move -eq -1 ]; then 
   # No moves
      score=0;
   fi

   echo "returned $score;$move" >&2
   echo "$score;$move"
}

validate_input() {
   input=$1
   shift;
   b=("$@")
   if [ ${b[$input]} -eq $NONE ]; then
     return 0;
   fi
   return 1;
}

#a=( 0 0 0 0 0 0 0 0 0 )
a=( 0 0 0 0 0 0 0 0 0 )
#a=( -1 0 0 -1 0 0 0 0 0 )

w=$NOT_OVER
while [ $w -eq $NOT_OVER ]; do 
  print_board ${a[@]}
  r=`check_result ${a[@]}`
  
  if [ $r -eq $OPPONENT_WINS ]; then 
     printf "\nYou won!\n"; 
     break
  elif [ $r -eq $WE_WIN ]; then
     printf "\nI won!\n"; 
     break
  elif [ $r -eq $DRAW ]; then
     printf "\nDraw!\n"; 
     break  
  fi
 
  while true; do
    echo "Where to put X ? "
    read x;
    validate_input $x ${a[@]}
    if [ $? -eq 0 ] ; then
       a[$x]=$OPPONENT
       break;
    fi
  done
  print_board ${a[@]}
  move_score=`calc_move $WE 1 ${a[@]}`
  move=`echo $move_score| cut -d \; -f 2`
  if [ -n "$move" -a \( $move -ge 0 \) ] ; then
     echo "I put o at $move ($move_score)"
     a[$move]=$WE
  fi
done
   
