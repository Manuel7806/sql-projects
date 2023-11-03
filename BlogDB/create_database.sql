/*
*
* Use this file to create the database and
* the database objects.
*
*/

USE master;

GO

-- Create the BlogDB database

BEGIN TRY
    CREATE DATABASE BlogDB;
END TRY
BEGIN CATCH
    IF EXISTS (SELECT * FROM [sys].[databases] WHERE [name] = 'BlogDB')
        PRINT 'BlogDB database already exists';
    ELSE
        PRINT 'Creating BlogDb database';
END CATCH

GO

-- Switch to the BlogDB database

USE BlogDB;

/*
*
* Create the user_roles table.
*
* We have to create the user_roles table
* before creating the users table because
* the users table depends on the user_roles table.
*
*/

BEGIN TRY
	CREATE TABLE [dbo].[user_roles] (
		[user_roles_id] INT NOT NULL IDENTITY(1,1),
		[role_name] NVARCHAR(9) NOT NULL,
		CONSTRAINT [PK_user_roles] PRIMARY KEY ([user_roles_id])
	);
END TRY
BEGIN CATCH
	IF EXISTS (SELECT * FROM [sys].[tables] WHERE [name] = 'user_roles')
		PRINT 'Table user_roles already exists';
	ELSE
		PRINT 'Creating table user_roles';
END CATCH;

GO

-- Create the users table

BEGIN TRY
	CREATE TABLE [dbo].[users] (
		[users_id] INT NOT NULL IDENTITY(1,1),
		[first_name] NVARCHAR(25) NOT NULL,
		[last_name] NVARCHAR(25) NOT NULL,
		[username] NVARCHAR(150) NOT NULL,
		[email] NVARCHAR(320) NOT NULL,
		[password] NVARCHAR(60) NOT NULL,
		[bio] NVARCHAR(MAX),
		[is_active] BIT NOT NULL CONSTRAINT [DF_users_is_active] DEFAULT 1, -- Default to 1 (true)
		[date_joined] DATETIMEOFFSET NOT NULL CONSTRAINT [DF_users_date_joined] DEFAULT CURRENT_TIMESTAMP, -- Default to current date and time
		[user_role_id] INT NOT NULL, -- The ID of the user_roles that corresponds to the users role
		CONSTRAINT [PK_users] PRIMARY KEY ([users_id]),
		CONSTRAINT [UQ_users_username_email] UNIQUE ([username], [email]),
		CONSTRAINT [FK_users_user_role_id] FOREIGN KEY ([user_role_id])
		REFERENCES [dbo].[user_roles]([user_roles_id])
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
	);
END TRY
BEGIN CATCH
	IF EXISTS (SELECT * FROM [sys].[tables] WHERE [name] = 'users')
		PRINT 'Table users already exists';
	ELSE
		PRINT 'Creating table uses';
END CATCH;

GO

-- Create indexes for the users table

CREATE INDEX [IX_users_username] ON [dbo].[users]([username]);

CREATE INDEX [IX_users_email] ON [dbo].[users]([email]);

CREATE INDEX [IX_users_is_active] ON [dbo].[users]([is_active]);

CREATE INDEX [IX_users_date_joined] ON [dbo].[users]([date_joined]);

GO

-- Create the user_permissions table

BEGIN TRY
	CREATE TABLE [dbo].[user_permissions] (
		[user_permissions_id] INT NOT NULL IDENTITY(1,1),
		[permission] NVARCHAR(25) NOT NULL,
		CONSTRAINT [PK_user_permissions] PRIMARY KEY ([user_permissions_id]),
		CONSTRAINT [UQ_user_permissions_permission] UNIQUE ([permission]) -- Ensure that the type of permission can only be in the table once
	);
END TRY
BEGIN CATCH
	IF EXISTS (SELECT * FROM [sys].[tables] WHERE [name] = 'user_permissions')
		PRINT 'Table user_permissions already exists.';
	ELSE
		PRINT 'Creating table user_permissions';
END CATCH;

GO

-- Create indexes for the user_permissions table

CREATE INDEX [IX_user_permissions_permission] ON [dbo].[user_permissions]([permission])

GO

-- Create the user_role_permissions table

BEGIN TRY
	CREATE TABLE [dbo].[user_role_permissions] (
		[user_role_id] INT NOT NULL, -- The ID of the user role
		[user_permission_id] INT NOT NULL, -- The ID of the user permission
		CONSTRAINT [PK_user_role_permissions] PRIMARY KEY ([user_role_id], [user_permission_id]),
		CONSTRAINT [FK_user_role_permissions_user_role] FOREIGN KEY ([user_role_id])
		REFERENCES [dbo].[user_roles]([user_roles_id])
		ON UPDATE NO ACTION
		ON DELETE NO ACTION,
		CONSTRAINT [FK_user_role_permissions_user_permission] FOREIGN KEY ([user_permission_id])
		REFERENCES [dbo].[user_permissions]([user_permissions_id])
		ON UPDATE NO ACTION
		ON DELETE NO ACTION
	);
END TRY
BEGIN CATCH
	IF EXISTS (SELECT * FROM [sys].[tables] WHERE [name] = 'user_role_permissions')
		PRINT 'Table user_role_permissions already exists';
	ELSE
		PRINT 'Creating table user_role_permissions';
END CATCH;

-- Create the followers table

BEGIN TRY
	CREATE TABLE [dbo].[followers] (
		[follower_id] INT NOT NULL, -- The ID of the user that initiated the follow
		[followee_id] INT NOT NULL, -- The ID of the user that is being followed
		[follow_date] DATETIMEOFFSET NOT NULL CONSTRAINT [DF_followers_follow_date] DEFAULT CURRENT_TIMESTAMP, -- Default to current date and time
		CONSTRAINT [PK_followers] PRIMARY KEY ([follower_id], [followee_id]), -- Compound key of both the follower_id and the followee_id
		CONSTRAINT [FK_followers_follower] FOREIGN KEY ([follower_id])
		REFERENCES [dbo].[users]([users_id])
		ON UPDATE NO ACTION
		ON DELETE CASCADE, -- If the user that initiated the follow is deleted, remove all related records in the table
		CONSTRAINT [FK_followers_followee] FOREIGN KEY ([followee_id])
		REFERENCES [dbo].[users]([users_id])
		ON UPDATE NO ACTION
		ON DELETE NO ACTION
	);
END TRY
BEGIN CATCH
	IF EXISTS (SELECT * FROM [sys].[tables] WHERE [name] = 'followers')
		PRINT 'Table followers already exists.';
	ELSE
		PRINT 'Creating table followers.';
END CATCH;

-- Create the social_media_links table

BEGIN TRY
	CREATE TABLE [dbo].[social_media_links] (
		[social_media_links_id] INT NOT NULL IDENTITY(1,1),
		[site_name] NVARCHAR(150) NOT NULL,
		[site_url] NVARCHAR(150) NOT NULL,
		[user_id] INT NOT NULL, -- The ID of the user the social media site belongs to
		CONSTRAINT [PK_social_media_links] PRIMARY KEY ([social_media_links_id]),
		CONSTRAINT [FK_social_media_links_user] FOREIGN KEY ([user_id])
		REFERENCES [dbo].[users]([users_id])
		ON UPDATE NO ACTION
		ON DELETE CASCADE, -- If the user that created the social media site is deleted, remove all social media links related to that user
	);
END TRY
BEGIN CATCH
	IF EXISTS (SELECT * FROM [sys].[tables] WHERE [name] = 'social_media_links')
		PRINT 'Table social_media_links already exists.';
	ELSE
		PRINT 'Creating table social_media_links.';
END CATCH;

GO

-- Create indexes for the social_media_links table

CREATE INDEX [IX_social_media_links_user] ON [dbo].[social_media_links]([user_id]);

GO

-- Create the posts table

BEGIN TRY
	CREATE TABLE [dbo].[posts] (
		[posts_id] INT NOT NULL IDENTITY(1,1),
		[title] NVARCHAR(200) NOT NULL,
		[body] NVARCHAR(MAX) NOT NULL,
		[status] NVARCHAR(9) NOT NULL CONSTRAINT [DF_posts_status] DEFAULT 'published', -- Default status to 'publish'
		[views] INT NOT NULL CONSTRAINT [DF_posts_views] DEFAULT 0, -- Default to 0 (no views)
		[date_posted] DATETIMEOFFSET NOT NULL CONSTRAINT [DF_post_date_posted] DEFAULT CURRENT_TIMESTAMP, -- Default to current date and time
		[last_updated] DATETIMEOFFSET NOT NULL CONSTRAINT [DF_post_last_updated] DEFAULT CURRENT_TIMESTAMP,
		[user_id] INT NOT NULL, -- The ID of the user that created the post
		CONSTRAINT [PK_posts] PRIMARY KEY ([posts_id]),
		CONSTRAINT [UQ_posts_title] UNIQUE ([title]),
		CONSTRAINT [CHK_posts_status] CHECK( [status] IN ('published', 'draft') ), -- Ensures that the status attribute can only be 'published' or 'draft'
		CONSTRAINT [FK_posts_user] FOREIGN KEY ([user_id])
		REFERENCES [dbo].[users]([users_id])
		ON UPDATE NO ACTION
		ON DELETE CASCADE -- Delete all related records if the user that created the posts is deleted
	);
END TRY
BEGIN CATCH
	IF EXISTS (SELECT * FROM [sys].[tables] WHERE [name] = 'posts')
		PRINT 'Table posts already exists.';
	ELSE
		PRINT 'Creating posts table.';
END CATCH;

GO

-- Create indexes for the posts table

CREATE INDEX [IX_posts_date_posted] ON [dbo].[posts]([date_posted]);

CREATE INDEX [IX_posts_status] ON [dbo].[posts]([status]);

CREATE INDEX [IX_posts_views] ON [dbo].[posts]([views]);

CREATE INDEX [IX_posts_user_id] ON [dbo].[posts]([views]);

GO

-- Create table post_images

BEGIN TRY
	CREATE TABLE [dbo].[post_images] (
		[post_images_id] INT NOT NULL IDENTITY(1,1),
		[image_url] NVARCHAR(200) NOT NULL, -- URL safe string that points to the server where the image is stored
		[post_id] INT NOT NULL, -- The ID of the post that the image belongs to
		CONSTRAINT [PK_post_images] PRIMARY KEY ([post_images_id]),
		CONSTRAINT [FK_post_images_post] FOREIGN KEY ([post_id])
		REFERENCES [dbo].[posts]([posts_id])
		ON UPDATE NO ACTION
		ON DELETE CASCADE, -- Remove all related records if the parent post is deleted
	);
END TRY
BEGIN CATCH
	IF EXISTS (SELECT * FROM [sys].[tables] WHERE [name] = 'post_images')
		PRINT 'Table post_images alread exists.';
	ELSE
		PRINT 'Creating post_images table.';
END CATCH;

GO

-- Create indexes for the post_images table

CREATE INDEX [IX_post_images_post_id] ON [dbo].[post_images]([post_id]);

GO

-- Create the comments table

BEGIN TRY
	CREATE TABLE [dbo].[comments] (
		[comments_id] INT NOT NULL IDENTITY(1,1),
		[body] NVARCHAR(MAX) NOT NULL,
		[date_posted] DATETIMEOFFSET NOT NULL CONSTRAINT [DF_comments_date_posted] DEFAULT CURRENT_TIMESTAMP, -- Default to current date and time
		[post_id] INT NOT NULL, -- The ID of the post that the comment was made on
		[user_id] INT NOT NULL, -- The ID of the user that made the comment
		CONSTRAINT [PK_comments] PRIMARY KEY ([comments_id]),
		CONSTRAINT [FK_comments_post] FOREIGN KEY ([post_id])
		REFERENCES [dbo].[posts]([posts_id])
		ON UPDATE NO ACTION
		ON DELETE CASCADE, -- Delete all related comments if the post is deleted
		CONSTRAINT [FK_comments_user] FOREIGN KEY ([user_id])
		REFERENCES [dbo].[users]([users_id])
		ON UPDATE NO ACTION
		ON DELETE NO ACTION
	);
END TRY
BEGIN CATCH
	IF EXISTS (SELECT * FROM [sys].[tables] WHERE [name] = 'comments')
		PRINT 'Table comments already exists.';
	ELSE
		PRINT 'Creating comments table.';
END CATCH;

GO

-- Create indexes for comments

CREATE INDEX [IX_comments_date_posted] ON [dbo].[comments]([date_posted]);

CREATE INDEX [IX_comments_post_id] ON [dbo].[comments]([post_id]);

CREATE INDEX [IX_comments_user_id] ON [dbo].[comments]([user_id]);

-- Create the comment_on_comments table

BEGIN TRY
	CREATE TABLE [dbo].[comment_on_comments] (
		[comment_on_comments_id] INT NOT NULL IDENTITY(1,1),
		[body] NVARCHAR(MAX) NOT NULL,
		[date_posted] DATETIMEOFFSET NOT NULL CONSTRAINT [DF_comment_on_comments_date_posted] DEFAULT CURRENT_TIMESTAMP, -- Default to current date and time
		[comment_id] INT NOT NULL, -- The ID of the parent comment
		[user_id] INT NOT NULL, -- The ID of the user that created the nested comment
		CONSTRAINT [PK_comment_on_comments] PRIMARY KEY ([comment_on_comments_id]),
		CONSTRAINT [FK_comment_on_comments] FOREIGN KEY ([comment_id])
		REFERENCES [dbo].[comments]([comments_id])
		ON UPDATE NO ACTION
		ON DELETE CASCADE, -- IF the parent comment is delted, delete all related nested comments
		CONSTRAINT [FK_comment_on_comments_user] FOREIGN KEY ([user_id])
		REFERENCES [dbo].[users]([users_id])
		ON UPDATE NO ACTION
		ON DELETE NO ACTION
	);
END TRY
BEGIN CATCH
END CATCH;

GO

-- Create indexes for the comment_on_comments table

CREATE INDEX [IX_comment_on_comments_date_posted] ON [dbo].[comment_on_comments]([date_posted]);

CREATE INDEX [IX_comment_on_comments_comment_id] ON [dbo].[comment_on_comments]([comment_id]);

CREATE INDEX [IX_comment_on_comments_user_id] ON [dbo].[comment_on_comments]([user_id]);

GO

-- Create the categories table

BEGIN TRY
	CREATE TABLE [dbo].[categories] (
		[category_id] INT NOT NULL IDENTITY(1,1),
		[name] NVARCHAR(25) NOT NULL,
		CONSTRAINT [PK_categories] PRIMARY KEY ([category_id]),
		CONSTRAINT [UQ_categories_name] UNIQUE ([name]) -- Ensures that a category can't share the same name more than once
	);
END TRY
BEGIN CATCH
	IF EXISTS (SELECT * FROM [sys].[tables] WHERE [name] = 'categories')
		PRINT 'Table categories already exists.';
	ELSE
		PRINT 'Creating table categories.';
END CATCH;

GO

-- Create indexes for the categories table

CREATE INDEX [IX_categories_name] ON [dbo].[categories]([name]);

GO

