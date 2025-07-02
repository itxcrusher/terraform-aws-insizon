#!/bin/bash
# Working hard
environment="dev"





prompt_select() {
title="Select example"
prompt="Pick an option:"
options=("Key.sh" "Fmt.sh" "Plan.sh" "Apply.sh" "Output.sh" "Key-single.sh" "Destory.sh" "Push.sh")

echo "$title"
PS3="$prompt "
select opt in "${options[@]}" "Quit"; 
do 
    case "$REPLY" in
    1) 
      echo "You picked $opt which is option 1"
      bash "./create-all-cloudfront-keys.sh"
      ;;
    2) 
      echo "You picked $opt which is option 2"
      bash "./fmt.sh"
      ;;
    3) 
      echo "You picked $opt which is option 3"
      bash "./plan.sh" "$environment"
      ;;
    4) 
      echo "You picked $opt which is option 3"
      bash "./apply.sh" "$environment"
      ;;
     5) 
      echo "You picked $opt which is option 3"
      bash "./output.sh"
      ;;
     6) 
      echo "You picked $opt which is option 3"
      bash "./create-single-cloudfront-key.sh"
      ;;
      7) 
      echo "You picked $opt which is option 3"
      # bash "./destory.sh"
      ;;
      8) 
      echo "You picked $opt which is option 3"
      bash "./push.sh"
      ;;
      9) 
        echo "Goodbye!"; 
        break
        ;;
      *) 
        echo "Invalid option. Try another one.";
        echo "#####################################"
        echo "${options[@]}" "Quit"
        echo "#####################################"
        continue
        ;;
    esac
done
}

prompt_select