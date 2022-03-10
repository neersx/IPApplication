
/**********************************************************************************************************/
/*** DR-45665 Ability to specify Practitioner sponsorship to enable automated USPTO download			***/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Sponsorships')
BEGIN
    CREATE TABLE [dbo].[Sponsorships](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[SponsorName] [nvarchar](max) NOT NULL,
	[SponsoredAccount] [nvarchar](max) NOT NULL,
	[CustomerNumbers] [nvarchar](max) NOT NULL,
	[ServiceId] [nvarchar](max) NULL,
	[CreatedOn] [datetime] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[DeletedOn] [datetime] NULL,
	[DeletedBy] [int] NULL,
	[Status] [SMALLINT] NOT NULL DEFAULT 0,
	[StatusDate] [DATE] NOT NULL DEFAULT GETDATE(),
	[StatusMessage] [NVARCHAR](max) NULL
 CONSTRAINT [PK_dbo.Sponsorships] PRIMARY KEY CLUSTERED ([Id] ASC))
PRINT '**** DR-45665 Table Sponsorships Added'
END
PRINT '**** DR-45665 Table Sponsorships Already Exists'           
GO
