SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Abbasi
-- Create date: 2021-12-06
-- Description:	This Stored Procedure Created For Logging Data Of One Table That Table Deleted By Condition
-- =============================================
--EXEC [GNR].[DeleteEntity] null,null,null,null,null,null,N'sadgan001',N'GNR',N'Bank',N'WHERE Code>=34'
Alter PROCEDURE [GNR].[DeleteEntity] 
	-- Add the parameters for the stored procedure here
	 @UserId int=NULL
	,@SubSystemID int=NULL
	,@FormId int=NULL
	,@ActionId int=NULL
	,@Message nvarchar(1000)=NULL
	,@ChangeSetId int =NULL
	,@MainDataBase nvarchar(100)
	,@Schema nvarchar(50)
	,@Table nvarchar(50)
	,@Condition nvarchar(1000)
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @DataTable TABLE(ID int,XmlData xml,JsonData varchar(max) NULL)

	DECLARE @SelectIDCommand nvarchar(max)

	SET    @SelectIDCommand =N'SELECT ID FROM '+@MainDataBase+N'.'+@Schema+'.'+@Table+' '+@Condition

	INSERT INTO @DataTable(ID)
	EXEC sp_executesql @SelectIDCommand

	-------------------------------------------------------Cursor:Take Xml Data For Every ID
DECLARE @Id int
DECLARE db_cursor CURSOR FOR 
							SELECT ID FROM @DataTable temptable

	OPEN db_cursor  
			FETCH NEXT FROM db_cursor INTO @Id  

			WHILE @@FETCH_STATUS = 0  
				BEGIN  

					   DECLARE @idCondition nvarchar(50)=N' ID='+Convert(nvarchar(10),@id)

					   IF @Condition IS NOT NULL
						 SET @idCondition=N' AND '+@idCondition
					   DECLARE @xmldata xml
					   DECLARE @cmd nvarchar(2000)= N'SELECT @result=(SELECT *  FROM '+@MainDataBase+N'.'+@Schema+N'.'+@Table+N' '+@condition+@idCondition+N' For XML PATH'+N')'
	  
					   EXEC sp_executesql @cmd,N'@result xml OUTPUT',@xmldata OUT

					   --select @cmd

					   --select @xmldata
					   UPDATE @DataTable  SET xmlData=@xmldata WHERE ID=@Id
					FETCH NEXT FROM db_cursor INTO @id
				END 

	CLOSE db_cursor  
DEALLOCATE db_cursor 

	----------------------------------------------------------Create Json From XmlData
	UPDATE @DataTable SET JsonData= GNR.FnXmlToJson(xmldata)

	
	----------------------------------------------------------Change Json To SoftWare Json Structure
	DECLARE @jsonItemRoot nvarchar(50)=N'EntityAfterChange'
	UPDATE @DataTable set JsonData=
	CASE WHEN LEN(jsondata)>=3 THEN N'{ '+N'"'+@jsonItemRoot+N'"'+N': '+SUBSTRING(JsonData,3,LEN(jsondata)-3)+N' }'
	ELSE NULL END

	
	DECLARE @EntityStatus nvarchar(20)=N'Deleted'--Deleted
				
	--SELECT * FROM @DataTable
	
	DECLARE @LogDatabase nvarchar(50)=N'sadgan001'
	DECLARE @LogSchema nvarchar(50)=N'GNR'
	DECLARE @LogTable nvarchar(50)=N'AuditLog'
	Declare @InsertCommandTable TABLE(Command varchar(max))
	Declare @InsertCommand nvarchar(max)
	Declare @JsonData varchar(max)



DECLARE Cursor_CreateCommand CURSOR FOR ---------------------------------------------Cursor:Create Command For Insert To Log
							SELECT ID,JsonData FROM @DataTable temptable

	OPEN Cursor_CreateCommand  
			FETCH NEXT FROM Cursor_CreateCommand INTO @Id,@JsonData

			WHILE @@FETCH_STATUS = 0  
				BEGIN  
					SET @InsertCommand=N'INSERT INTO '+
											@LogDatabase+N'.'+@LogSchema+N'.'+@LogTable
											+N'('
												+N'ServerDateTime'
												+N',LocalDateTime'
												+N',Level'
												+N',Logger'
												+N',Message'
												+N',StackTrace'
												+N',Exception'
												+N',RefUserID'
												+N',EntityName'
												+N',EntityStatus'
												+N',EntityPrimaryKeyValue'
												+N',EntityAfterChange'
												+N',LocalIp'
												+N',HostName'
												+N',MachinName'
												+N',AppDomain'
												+N',AppVersion'
												+N',AppPath'
												+N',ProcessId'
												+N',RefChangeSetID'
												+N',RefSubSystemID'
													+N')'
											+N'SELECT '
												+N'GETDATE()'
												+N',GETDATE()'
												+N',''Info'''
												+N',''Name Of StoredProcedure'''
												+N','+ CASE WHEN @Message IS NULL THEN N'NULL' ELSE N''''+@Message+N'''' END
												+N',NULL'
												+N',NULL'
												+N','
												+CASE WHEN @UserId IS NULL THEN N'NULL' ELSE CONVERT(nvarchar,@UserId) end
												+N','''+@Schema+N'.'+@Table+N''''
												+N','+CASE WHEN @EntityStatus IS NULL THEN N'NULL' ELSE N''''+@EntityStatus+N'''' END
												+N','+Convert(nvarchar,@Id)
												+N','+CASE WHEN @JsonData IS NULL THEN N'NULL' ELSE N''''+Convert(nvarchar(MAX),@JsonData)+N'''' END
												+N',NULL'
												+N',NULL'
												+N',NULL'
												+N',NULL'
												+N',NULL'
												+N',NULL'
												+N',NULL'
												+N','+CASE WHEN @ChangeSetId IS NULL THEN N'NULL' ELSE Convert(nvarchar,@ChangeSetId) END
												+N','+CASE WHEN @SubSystemID IS NULL THEN N'NULL' ELSE Convert(nvarchar,@SubSystemID) END
												INSERT INTO @InsertCommandTable(Command) SELECT @InsertCommand
												PRINT'INSERT:'
												print @InsertCommand
												EXEC sp_executesql @insertcommand-------------------------------Insert Json Data To Log
												
					FETCH NEXT FROM Cursor_CreateCommand INTO @Id,@JsonData
				END 

	CLOSE Cursor_CreateCommand  
DEALLOCATE Cursor_CreateCommand 
	
	--SELECT * FROM @InsertCommandTable

	DECLARE @DeleteCommand nvarchar(max)=N'DELETE FROM '+@MainDataBase+N'.'+@schema+N'.'+@Table+N' '+@Condition
	EXEC sp_executesql @DeleteCommand--------------------------------------------------------------------------Delete Data From Main DataBase

	--SELECT @DeleteCommand DeleteCommand
	--EXEC [GNR].[DeleteEntity] null,null,null,null,null,null,N'sadgan001',N'GNR',N'Bank',N'WHERE Code>=34' select * from GNR.AuditLog order by id desc
	--select * from gnr.auditlog
END
GO
