using System.Collections.Generic;
using System.Threading.Tasks;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.Names.Consolidations
{
    public interface IBatchedCommand
    {
        Task ExecuteAsync(string sqlCommand, Dictionary<string, object> parameters);
    }

    public class BatchedCommand : IBatchedCommand
    {
        readonly IDbContext _dbContext;
        readonly IConsolidationSettings _consolidationSettings;

        public BatchedCommand(IDbContext dbContext, IConsolidationSettings consolidationSettings)
        {
            _dbContext = dbContext;
            _consolidationSettings = consolidationSettings;
        }

        /// <summary>
        /// This is a placeholder component until the below tech-debts can be paid.
        /// </summary>
        public async Task ExecuteAsync(string sqlCommand, Dictionary<string, object> parameters)
        {
            /*
             * TECH-DEBT
             *
             * The issue is with syntax such as this cannot be effectively achieved with EF and the closest
             * we have to it remains as feature requests in the below
             *
             *    INSERT (xxx,yyy,zzz)
             *    SELECT xxx, yyy, zzz1
             *    FROM SOMEWHERE
             *
             * EF by default requires the entities to be returned, and possibly detached with the new values assigned
             * before the entity is added via AddRange (adding via Add triggers DetectChanges for each Add) which triggers DetectChanges
             * then the constructed INSERT statements are issued for each entity.  Each entity insertion requires a roundtrip.
             *
             * For NAME CONSOLIDATION this is terrible for tables with large number of records (e.g. > 10,000 entities to insert)
             *
             * https://github.com/zzzprojects/EntityFramework-Plus/issues/196
             * https://github.com/zzzprojects/EntityFramework-Plus/issues/306
             *
             * Also for complex Updates where the set assignments are from a different entity than the main entity are not supported. for example:
             * the below references of NT (NAMETYPE) and AN (ASSOCIATEDNAME) are not supported in UpdateExpression
             *
        UPDATE CN 
        SET CORRESPONDNAME =   case when ( CN.DERIVEDCORRNAME = 0 ) then @pnNameNoConsolidateTo                         
                        when ( convert(bit,NT.COLUMNFLAGS&1)=0 and CN.NAMETYPE not in ('I','A') ) then NULL            
                        when ( AN.CONTACT is not null ) then AN.CONTACT            
                        else dbo.fn_GetDerivedAttnNameNo( CN.NAMENO, CN.CASEID, CN.NAMETYPE )   
                    end  
        from CASENAME CN  
        join NAMETYPE NT on (NT.NAMETYPE = CN.NAMETYPE)  
        left join ASSOCIATEDNAME AN on (AN.NAMENO = CN.INHERITEDNAMENO      
                        and AN.RELATIONSHIP = CN.INHERITEDRELATIONS      
                        and AN.RELATEDNAME = CN.NAMENO      
                        and AN.SEQUENCE = CN.INHERITEDSEQUENCE) 
        WHERE CN.CORRESPONDNAME = @pnNameNoConsolidateFrom
             * 
             * Likewise, DeleteExpression such as the below is not supported
             *
        delete CN1
        from CASENAME CN1
        where NAMENO=@pnNameNoConsolidateTo
        and exists
        (select 1
         from CASENAME CN2
         where CN2.CASEID  =CN1.CASEID
         and   CN2.NAMETYPE=CN1.NAMETYPE
         and   CN2.NAMENO  =CN1.NAMENO
         and   CN2.SEQUENCE<CN1.SEQUENCE
         and   CHECKSUM(CN1.CORRESPONDNAME, CN1.ADDRESSCODE, CN1.REFERENCENO, CN1.ASSIGNMENTDATE, CN1.COMMENCEDATE, CN1.EXPIRYDATE, CN1.BILLPERCENTAGE, CN1.NAMEVARIANTNO, CN1.REMARKS, CN1.CORRESPONDENCESENT, CN1.CORRESPONDENCERECEIVED, CN1.CORRESPSENT, CN1.CORRESPRECEIVED)
             = CHECKSUM(CN2.CORRESPONDNAME, CN2.ADDRESSCODE, CN2.REFERENCENO, CN2.ASSIGNMENTDATE, CN2.COMMENCEDATE, CN2.EXPIRYDATE, CN2.BILLPERCENTAGE, CN2.NAMEVARIANTNO, CN2.REMARKS, CN2.CORRESPONDENCESENT, CN2.CORRESPONDENCERECEIVED, CN2.CORRESPSENT, CN2.CORRESPRECEIVED)
         )

             *
             **/

            using (var command = _dbContext.CreateSqlCommand(sqlCommand, parameters))
            {
                command.CommandTimeout = _consolidationSettings.Timeout;
                await command.ExecuteNonQueryAsync();
            }
        }
    }
}
