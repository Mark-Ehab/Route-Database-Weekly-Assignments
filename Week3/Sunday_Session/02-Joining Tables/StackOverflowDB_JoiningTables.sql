/* =====================================================================
	Use StackOverflow 2010 Database instead of master Database (Default)
=======================================================================*/
USE StackOverflow2010

/* ========================================
	1) Write a query to display all users 
	   along with all post types
===========================================*/
SELECT U.DisplayName AS 'User Display Name',
	   T.[Type] AS 'Post Type'
FROM Users AS U
FULL OUTER JOIN Posts AS P
ON P.PostTypeId = U.Id
FULL OUTER JOIN PostTypes AS T
ON P.PostTypeId = T.Id

/* ==================================================================
	2) Write a query to retrieve all posts along with their owner's
       display name and reputation.Only include posts that have an
       owner.
====================================================================*/
SELECT U.DisplayName AS 'Post Owner Display Name',
	   U.Reputation AS 'Post Owner Reputation',
	   P.Body AS 'Post Body'
FROM Posts AS P
INNER JOIN Users AS U
ON P.OwnerUserId = U.Id

/* ===================================================================
	3) Write a query to show all comments with their associated post
	   titles. Display the comment text, comment score, and post title.
=====================================================================*/
SELECT C.[Text] AS 'Comment Text',
	   C.Score AS 'Comment Score',
	   P.Title AS 'Post Title'
FROM Comments AS C
INNER JOIN Posts AS P
ON C.PostId = P.Id
--WHERE P.PostTypeId = 1

/* ===================================================================
	4) Write a query to list all users and their badges (if any).
       Include users even if they don't have badges. Show display name,
       badge name, and badge date.
=====================================================================*/
SELECT U.DisplayName AS 'User Display Name',
	   B.[Name] AS 'Badge Name',
	   B.[Date] AS 'Badge Date'
FROM Users AS U
LEFT JOIN Badges AS B
ON B.UserId = U.Id

/* ======================================================================
	5) Write a query to display all posts along with their comments (if
       any). Include posts that have no comments. Show post title, post
       score, comment text, and comment score.
========================================================================*/
SELECT P.Title AS 'Post Title',
	   P.Score AS 'Post Score',
       C.[Text] AS 'Comment Text',
	   C.Score AS 'Comment Score'
FROM Posts AS P
LEFT JOIN Comments AS C
ON C.PostId = P.Id
--WHERE P.PostTypeId = 1

/* ======================================================================
	6) Write a query to show all votes along with their corresponding
       posts. Include all votes even if the post information is missing.
       Display vote type ID, creation date, and post title.
========================================================================*/
SELECT V.VoteTypeId AS 'Vote Type Id', 
	   V.CreationDate AS 'Vote Creation Date',
	   P.Title AS 'Post Title'
FROM Votes AS V
INNER JOIN Posts AS P
ON V.PostId = P.Id

/* ======================================================================
	7) Write a query to find all answers (posts with ParentId) along with
       their parent question. Show the answer title, answer score,
       question title, and question score.
========================================================================*/
SELECT A.Title AS 'Answer Title',
	   A.Score AS 'Answer Score',
	   Q.Title AS 'Question Title',
	   Q.Score AS 'Question Score'
FROM Posts AS A
INNER JOIN Posts AS Q
ON A.ParentId = Q.Id

/* ===========================================================================
	8) Write a query to display all related posts using the PostLinks table.
	   Show the original post title, related post title, and link type ID.
==============================================================================*/
SELECT OriginalPost.Title AS 'Original Post Title',
	   RelatedPost.Title AS 'Related Post Title',
	   LinkType.Id AS 'Link Type ID'
FROM PostLinks AS PostLink
INNER JOIN Posts AS RelatedPost
ON PostLink.PostId = RelatedPost.Id
LEFT JOIN Posts AS OriginalPost
ON PostLink.RelatedPostId = OriginalPost.Id
INNER JOIN LinkTypes AS LinkType
ON PostLink.LinkTypeId = LinkType.Id

/* ===========================================================================
	9) Write a query to show posts with their authors and the post type
       name. Display post title, author display name, author reputation,
       and post type.
==============================================================================*/
SELECT P.Title AS 'Post Title', 
	   U.DisplayName AS 'Author Display Name',
	   U.Reputation AS 'Author Reputation', 
	   PT.[Type] AS 'Post Type'
FROM Posts AS P
INNER JOIN Users AS U
ON P.OwnerUserId = U.Id
INNER JOIN PostTypes AS PT
ON P.PostTypeId = PT.Id

/*============================================================================
	10) Write a query to retrieve all comments along with the post title,
        post author, and the commenter's display name.
==============================================================================*/

SELECT Post.Title AS 'Post Title', 
	   Author.DisplayName AS 'Author Name',
	   Commenter.DisplayName AS 'Commenter Name'
FROM Comments AS Comment
INNER JOIN Posts AS Post
ON Comment.PostId = Post.Id
LEFT JOIN Users AS Commenter
ON Comment.UserId = Commenter.id
INNER JOIN Users AS Author
ON Post.OwnerUserId = Author.id

/*============================================================================
	11) Write a query to display all votes with post information and vote
        type name. Show post title, vote type name, creation date, and
        bounty amount.
==============================================================================*/
SELECT P.Title AS 'Post Title',
	   VT.[Name] AS 'Vote Type Name',
	   V.CreationDate AS 'Vote Creation Date',
	   V.BountyAmount AS 'Vote Bounty Amount'
FROM Votes AS V
INNER JOIN Posts AS P
ON V.PostId = P.Id
INNER JOIN VoteTypes AS VT
ON V.VoteTypeId = VT.Id

/*============================================================================
	12) Write a query to show all users along with their posts and
        comments on those posts. Include users even if they have no
        posts or comments. Display user name, post title, and comment
        text.
==============================================================================*/
SELECT U.DisplayName AS 'User Name',
	   P.Title AS 'Post Title',
	   C.[Text] AS 'Comment Text'
FROM Users AS U
LEFT JOIN Posts AS P
ON P.OwnerUserId = U.Id
LEFT JOIN Comments AS C
ON C.PostId = P.Id

/*============================================================================
	13) Write a query to retrieve posts with their authors, post types, and
        any badges the author has earned. Show post title, author name,
        post type, and badge name.
==============================================================================*/
SELECT P.Title AS 'Post Title',
	   U.DisplayName AS 'Author Name',
	   PT.[Type] AS 'Post Type',
	   B.[Name] AS 'Badge Name'
FROM Posts AS P
INNER JOIN Users AS U
ON P.OwnerUserId = U.Id
INNER JOIN PostTypes AS PT
ON P.PostTypeId = PT.Id
INNER JOIN Badges AS B
ON B.UserId = U.Id

/*============================================================================
	14) Write a query to create a comprehensive report showing:
        post title, post author name, author reputation, comment text,
        commenter name, vote type, and vote creation date. Include
        posts even if they don't have comments or votes. Filter to only
        show posts with a score greater than 5.
==============================================================================*/
SELECT Post.Title AS 'Post Title',
	   Author.DisplayName AS 'Post Author Name',
	   Author.Reputation AS 'Author Reputation',
	   Comment.[Text] AS 'Comment Text',
	   Commenter.DisplayName AS 'Commenter Name',
	   VoteType.[Name] AS 'Vote Type',
	   Vote.CreationDate AS 'Vote Creation Date'
FROM Posts AS Post
INNER JOIN Users AS Author
ON Post.OwnerUserId = Author.Id
LEFT JOIN Comments AS Comment
ON Comment.PostId = Post.Id
LEFT JOIN Users AS Commenter
ON Comment.UserId = Commenter.Id
LEFT JOIN Votes AS Vote
ON Vote.PostId = Post.Id
LEFT JOIN VoteTypes AS VoteType
ON Vote.VoteTypeId = VoteType.Id
WHERE Post.Score > 5