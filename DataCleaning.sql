/* Add a column representing the country to every single table */

ALTER TABLE CAVideos
ADD Country nvarchar(max);
UPDATE CAVideos
SET Country = 'CA';

ALTER TABLE USVideos
ADD Country nvarchar(max);
UPDATE USVideos
SET Country = 'US';

ALTER TABLE FRVideos
ADD Country nvarchar(max);
UPDATE FRVideos
SET Country = 'FR';

ALTER TABLE INVideos
ADD Country nvarchar(max);
UPDATE INVideos
SET Country = 'IN';

ALTER TABLE GBVideos
ADD Country nvarchar(max);
UPDATE GBVideos
SET Country = 'GB';


/* Get the counts of every single country's data(Minimum found is 37352) */

SELECT COUNT(video_id) FROM CAVideos
SELECT COUNT(video_id) FROM USVideos
SELECT COUNT(video_id) FROM FRVideos
SELECT COUNT(video_id) FROM INVideos
SELECT COUNT(video_id) FROM GBVideos 

/* Make a new Videos column which unionizes all of the country columns */

SELECT TOP 0 *
INTO Videos
FROM CAVideos; 

INSERT INTO Videos

SELECT TOP 37352 * FROM CAVideos /* Since the minimum count is 37352, select top 37352 rows */
UNION ALL
SELECT TOP 37352 * FROM USVideos
UNION ALL
SELECT TOP 37352 * FROM FRVideos
UNION ALL
SELECT * FROM INVideos
UNION ALL
SELECT TOP 37352 * FROM GBVideos;

/* Calculate NULL amounts of every single column */

CREATE TABLE ColumnNames (
    ID int IDENTITY(1,1) PRIMARY KEY,
    [name] varchar(max),
    nullAmount int
)

INSERT INTO ColumnNames ([name]) 
SELECT [name] FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Videos')

DECLARE @columnIndex INT = 1

WHILE @columnIndex <= ( SELECT COUNT(*) FROM dbo.ColumnNames )
BEGIN
    DECLARE @colName nvarchar(max) = (SELECT [name] FROM ColumnNames WHERE ID = @columnIndex)
    EXEC('SELECT ' + @colName + ' INTO colTable FROM Videos')

    DECLARE @SQL nvarchar(max) = N'UPDATE ColumnNames SET nullAmount = (SELECT COUNT(1) - COUNT(' + quotename(@colName) + ') FROM colTable) WHERE ID = @columnIndex'
    EXEC SP_EXECUTESQL @SQL, N'@columnIndex int', @columnIndex 

    DROP TABLE colTable
    SET @columnIndex = @columnIndex + 1
END

SELECT * FROM ColumnNames
DROP TABLE ColumnNames;

/* Since Description is the only column with NULL values, replace the NULL with [none] */

UPDATE Videos 
SET [description] = '[none]'
WHERE [description] IS NULL; 

/* Add ISVEVO: Shows whether channel has VEVO in its title */

ALTER TABLE Videos
ADD [Is Vevo] nvarchar(max);

UPDATE Videos
SET [Is Vevo] = 
CASE
	WHEN channel_title LIKE '%VEVO' THEN 'True'
	ELSE 'False'
END;

/* Add Likes to Views Perc: Shows percentage of likes of views */

ALTER TABLE Videos
ADD [Likes:Views Perc] int;

UPDATE Videos
SET [Likes:Views Perc] = 
CASE
	WHEN (100 * [likes]) / [views] = 0 THEN 1 /* If the ratio is too small then round up */
	ELSE (100 * [likes]) / [views]
END;

/* Add Comments to Views Percentage: Shows percentage of comments who viewed */

ALTER TABLE Videos
ADD [Comments:Views Perc] int;

UPDATE Videos
SET [Comments:Views Perc] = 
CASE
	WHEN (100 * [comment_count]) / [views] = 0 THEN 1 /* If the ratio is too small then round up */
	ELSE (100 * [comment_count]) / [views]
END;

/* Add tags count: Shows number of tags in the video */

ALTER TABLE Videos
ADD [tags num] int;

UPDATE Videos
SET [tags num] = 
LEN([tags]) - LEN(REPLACE([tags], '|', ''));

/* Add a Like to Dislike Ratio which shows likes divided by dislikes */

ALTER TABLE Videos
ADD [Like:Dislike Ratio] int;

UPDATE Videos
SET [Like:Dislike Ratio] = 
CASE
	WHEN [dislikes] = 0 THEN 0 /* Avoid dividing by 0 */
	ELSE [likes] / [dislikes]
END;

/* Add Month Index: An index representing the month the video was published */

ALTER TABLE Videos
ADD [Month Index] int;

UPDATE Videos
SET [Month Index] = 
SUBSTRING([publish_time], 6, 2);

/* Hour: Hour of the publish time */

ALTER TABLE Videos
ADD [Hour] int;

UPDATE Videos
SET [Hour] = 
SUBSTRING([publish_time], 12, 2);

/* Title Length: Length of the title(Round to the nearest tenth, but not 0) */

ALTER TABLE Videos
ADD [Title Length] int;

UPDATE Videos
SET [Title Length] = 
CASE
	WHEN LEN([title]) / 10 = 0 THEN 10
	ELSE (LEN([title]) / 10) * 10
END; 

/* Store the number of days until trending(Month difference * 30 + Day difference) */

ALTER TABLE Videos
ADD [Days Until Trending] int;

UPDATE Videos
SET [Days Until Trending] = 
ABS(CAST(SUBSTRING([trending_date], 7, 2) AS int) - [Month Index]) * 30 + 
ABS(CAST(SUBSTRING([trending_date], 4, 2) AS int) - CAST(SUBSTRING([publish_time], 9, 2) AS int))

/* True or False statement that shows True if the video limits any sort of speech from viewers */

ALTER TABLE Videos
ADD [Limits Expression] nvarchar(max);

UPDATE Videos
SET [Limits Expression] = 
CASE
	WHEN CAST([comments_disabled] AS int) + CAST([ratings_disabled] AS int) = 0 THEN 'False'
	ELSE 'True'
END;

/* Remove parts of different nvarchar columns that have commas */

UPDATE Videos
SET [title] = 
REPLACE([title], ',', '');

UPDATE Videos
SET [description] = 
REPLACE([description], ',', '');

UPDATE Videos
SET [channel_title] = 
REPLACE([channel_title], ',', '');

UPDATE Videos
SET [tags] = 
REPLACE([tags], ',', '');

/* Remove /n from the description column */

UPDATE Videos
SET [description] = 
REPLACE(REPLACE([description], CHAR(13), ''), CHAR(10), '');
