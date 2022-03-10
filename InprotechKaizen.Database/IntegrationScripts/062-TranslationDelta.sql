﻿IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TranslationDelta') 
	BEGIN
		CREATE TABLE [dbo].[TranslationDelta](
			[Culture] [nvarchar](50) NOT NULL,
			[LastModified] [datetime2](7) NOT NULL,
			[Delta] [nvarchar](max) NOT NULL,
		 CONSTRAINT [PK_TranslationDelta] PRIMARY KEY CLUSTERED 
		(
			[Culture] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
		) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]			
END
GO