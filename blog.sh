#!/bin/bash
#please uncomment the set -x for debugging
#set -x
#testing 
#variavles declaration
DATABASE="/root/blog.db"
PRAGMA="PRAGMA foreign_keys = ON;"
green=`tput setaf 2`
red=`tput setaf 1`
reset=`tput sgr0`


#**************section begin for sqlite3 query table creation***********************

#creating CATEGORY_TBL(category table) if the table exists than throws error and skips .errors are logged in sqlite.log file ****
sqlite3 $DATABASE "CREATE TABLE CATEGORY_TBL(
category_id  INTEGER PRIMARY KEY  NOT NULL,
category_name VARCHAR(100) NOT NULL UNIQUE
);" 2>sqlite.log
#inserting value 1 and unrecognized to the CATEGORY_TBL table
sqlite3 $DATABASE "insert into CATEGORY_TBL (category_id,category_name) values (1,'unrecognized' );" 2>>sqlite.log

#comment table
sqlite3 $DATABASE "CREATE TABLE COMMENT_TBL(
comment_id INTEGER PRIMARY KEY  NOT NULL,
post_id INTEGER NOT NULL,
comment_content BLOB NOT NULL,
comment_emailid VARCHAR(100) NOT NULL,
comment_IP BLOB NOT NULL
);" 2>>sqlite.log

#post table
sqlite3 $DATABASE "CREATE TABLE POST_TBL ( 
post_id INTEGER PRIMARY KEY  NOT NULL,
post_content BLOB  NOT NULL,
post_date DATE NOT NULL,
post_category INTEGER DEFAULT 1,
post_title BLOB NOT NULL,
FOREIGN KEY (post_category ) REFERENCES  CATEGORY_TBL(category_id)
);" 2>>sqlite.log



#**************section ending for sql query table creation************************


case $1 in

#--help section begining -----------------------------------

"--help")
echo "${green}*************listing all the commands${reset}*******************"
cat <<EOF
**************************************************************
**************************************************************

1.blog.sh will be name of application itself.

2.blog.sh --help will list help and commands available

3.blog.sh post add "title" "content" will add a new blog a new blog post with title and content.

4.blog.sh post list will list all blog posts

5.blog.sh post search "keyword" will list all blog posts where “keyword” is found in title and/or content.

6.blog.sh post delete <post-id>

7.blog.sh category add "category-name" create a new category

8.blog.sh category list list all categories

9.blog.sh category assign <post-id> <cat-id> assign category to post

10.blog.sh post add "title" "content" --category "cat-name" will add a new    blog a new blog post with title, content and assign a category to it. It category doesn’t exist, it will be created first.

11.blog.sh category delete <category-id> for deleteing the category

12.blog.sh comment list for listing the comment

13.blog.sh comment delete <comment-id> for deleting the comment

****************************************************************
****************************************************************
EOF
;;
#--help section ending -----------------------------------

#post section begin -----------------------------------

"post")
case $2 in
"add")
if [ $# -eq 4 ]
then
echo "runing the sql command to insert the content into the post table"
#if [ -n "$3" ]
#then
#sqlite3 $DATABASE "$PRAGMA insert into POST_TBL (post_title,post_content,post_category,post_date) values (\"$1\",\"$2\",\"$3\",DATETIME('NOW'));"
#else
sqlite3 $DATABASE "insert into POST_TBL (post_title,post_content,post_date) values (\"$3\",\"$4\",DATETIME('NOW'));"
#fi
#content and title inserted into the post_tbl *****************

#exit 0
#fi
else

if [ $# -eq 6 ] && [ $5 == "--category" ] 
then 
categoryid=`sqlite3 $DATABASE " select category_id from CATEGORY_TBL where category_name = \"$6\" "`
( [ ! -z $categoryid ]&& sqlite3 $DATABASE "$PRAGMA insert into POST_TBL (post_title,post_content,post_category,post_date) values (\"$3\",\"$4\",\"$categoryid\",DATETIME('NOW'));" && echo "${green}new blog with the category,title and content has been created${reset}" ) || ( sqlite3 $DATABASE "insert into CATEGORY_TBL (category_name) values (\"$6\");" &&  categoryid=`sqlite3 $DATABASE " select category_id from CATEGORY_TBL where category_name = \"$6\" "` && sqlite3 $DATABASE "$PRAGMA insert into POST_TBL (post_title,post_content,post_category,post_date) values (\"$3\",\"$4\",\"$categoryid\",DATETIME('NOW'));" && echo "${green}new blog with the category,title and content has been created${reset}" )
else
echo "${red}Please use the correct command and check --help for listing available commands${reset}"
fi
#((  [ $# -eq 6 ] && [ $5 == "--category" ]  )|| echo "please enter correct coomand " )&& sqlite3 $DATABASE "$PRAGMA insert into POST_TBL (post_title,post_content,post_category,post_date) values (\"$3\",\"$4\",\"$6\",DATETIME('NOW'));"
fi
;;
"list")
Pid=`sqlite3 $DATABASE "select exists (select 1 from POST_TBL);"`
if [ $Pid -eq 0 ]
then
echo "${red}Post table is empty${reset}"
else
#sqlite3 $DATABASE "select * from POST_TBL;"
sqlite3 $DATABASE <<EOQery
.mode column
.headers on
select * from POST_TBL;
EOQery
fi
;;
"search")
echo "running the sql query for searching keyword"

sqlite3 $DATABASE "select * from POST_TBL where post_content like '%"$3"%' ;" 2>>sqlite.log || echo "${red}keyword is not found ${reset}"
;;
"delete")

postid=`sqlite3 $DATABASE " select post_id from POST_TBL where post_id = \"$3\" "`
( [ ! -z $postid  ] && read -p "Please press y to delete: " val && [[ $val == "y" ]] &&  sqlite3 $DATABASE "delete from POST_TBL where post_id=\"$3\";" && echo "${green}Post has been deleted${reset}" )|| echo "${red}Post id not  found to delete.Please enter the correct post ID to delete ${reset}"

;;
*)
echo "${red}Please use the correct command and check --help for listing available commands ${reset}"
;;
esac

#post section ending -----------------------------------

#category begin ----------------------------------------

;;
"category")
case $2 in
"list")
Cateid=`sqlite3 $DATABASE "select exists (select 1 from CATEGORY_TBL);"`
if [ $Cateid -eq 0 ]
then
echo "${red}Category table is empty${reset}"
else

#sqlite3 $DATABASE "select * from CATEGORY_TBL;"
sqlite3 $DATABASE <<EOQery
.mode column
.headers on
select * from CATEGORY_TBL;
EOQery
fi

;;
"delete")
categoryid=`sqlite3 $DATABASE " select category_id from CATEGORY_TBL where category_id = \"$3\" "`
( [ ! -z $categoryid  ] && read -p "Please press y to delete: " val && [[ $val == "y" ]] &&  sqlite3 $DATABASE "delete from CATEGORY_TBL where category_id=\"$3\";" && echo "${green}Category has been deleted${reset}" )|| echo "${red}Category id not  found to delete.Please enter the correct category ID to delete ${reset}"

;;
"add")
if [ $# -eq 3 ]
then
 ( sqlite3 $DATABASE "insert into CATEGORY_TBL (category_name) values (\"$3\");" 2>>sqlite.log && echo "${green}Category has been entered into the category table ${reset}" ) || echo "${red}Category is already present so cant be added${reset}"
#echo "${green}category has been entered into the category table ${reset}"
exit 0
else 
echo "${red}Please enter the correct command ${reset}"
fi
;;
"assign")
re='^[0-9]+$'
( [ $# -eq 4 ]  &&  [[ $3 =~ $re ]] &&  [[ $4 =~ $re ]] && sqlite3 $DATABASE "$PRAGMA update POST_TBL set post_category = $4 where post_id = $3" 2>>sqlite.log && echo $"${green}category has been assigned to post${reset}" )|| echo "${red}Please check if category id is present in category tableand enter the correct ID${reset}" 

;;
*)

echo "${red}please enter the correct command ${reset}"
esac

#category ending ----------------------------------------


#comment section begin -----------------------------------

;;
"comment")
case $2 in
"list")
commentid=`sqlite3 $DATABASE "select exists (select 1 from COMMENT_TBL);"`
if [ $commentid -eq 0 ]
then
echo "${red}Comment table is empty${reset}"
else
sqlite3 $DATABASE <<EOQery
.mode column
.headers on
select * from COMMENT_TBL;
EOQery
fi

;;
"delete")

commentid=`sqlite3 $DATABASE " select comment_id from COMMENT_TBL where comment_id = \"$3\" "`
( [ ! -z $commentid  ] && read -p "Please press y to delete: " val && [[ $val == "y" ]] &&  sqlite3 $DATABASE "delete from COMMENT_TBL where comment_id=\"$3\";" && echo "${green}Comment has been deleted${reset}" )|| echo "${red}Comment id not  found to delete.Please enter the correct comment ID to delete ${reset}"

;;
*)
echo "please submit a correct command"
;;
esac
;;
#comment section ending -----------------------------------
*)
echo "${red}Please use the correct command and check --help for listing available commands ${reset}"
;;
esac
