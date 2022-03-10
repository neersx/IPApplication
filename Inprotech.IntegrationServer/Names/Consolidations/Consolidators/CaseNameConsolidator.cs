using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

#pragma warning disable 618

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class CaseNameConsolidator : INameConsolidator
    {
        readonly IBatchedCommand _batchedCommand;
        readonly IDbContext _dbContext;

        public CaseNameConsolidator(IDbContext dbContext, IBatchedCommand batchedCommand)
        {
            _dbContext = dbContext;
            _batchedCommand = batchedCommand;
        }

        public string Name => nameof(CaseNameConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            var parameters = new Dictionary<string, object>
            {
                {"@to", to.Id},
                {"@from", from.Id}
            };

            await UpdateAttentionName(parameters);

            await UpdateInheritedName(to, from);

            await UpdateName(to, from);

            await DeleteDuplicateCaseNames(parameters);

            await DeleteDuplicateCaseNameInheritancePointers(parameters);

            await DeleteNameAddressReference(from, option);
        }

        async Task DeleteNameAddressReference(Name from, ConsolidationOption option)
        {
            if (option.KeepConsolidatedName) return;

            if (option.KeepAddressHistory
                || _dbContext.Set<CaseName>().Any(_ => _.NameId == from.Id && _.Address != null)
                || _dbContext.Set<NameAddressCpaClient>().Any(_ => _.NameId == from.Id))
            {
                await _dbContext.DeleteAsync(from na in _dbContext.Set<NameAddress>()
                                             where na.NameId == @from.Id
                                             select na);
            }
        }

        async Task DeleteDuplicateCaseNameInheritancePointers(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            delete CN1
		    from CASENAME CN1
		    where CORRESPONDNAME=@to
		    and exists
		    (select 1
		     from CASENAME CN2
		     where CN2.CASEID        =CN1.CASEID
		     and   CN2.NAMETYPE      =CN1.NAMETYPE
		     and   CN2.NAMENO        =CN1.NAMENO
		     and   CN2.CORRESPONDNAME=CN1.CORRESPONDNAME
		     and   CN2.SEQUENCE      <CN1.SEQUENCE
		     and   CHECKSUM(CN1.ADDRESSCODE, CN1.REFERENCENO, CN1.ASSIGNMENTDATE, CN1.COMMENCEDATE, CN1.EXPIRYDATE, CN1.BILLPERCENTAGE, CN1.NAMEVARIANTNO, CN1.REMARKS, CN1.CORRESPONDENCESENT, CN1.CORRESPONDENCERECEIVED, CN1.CORRESPSENT, CN1.CORRESPRECEIVED)
		         = CHECKSUM(CN2.ADDRESSCODE, CN2.REFERENCENO, CN2.ASSIGNMENTDATE, CN2.COMMENCEDATE, CN2.EXPIRYDATE, CN2.BILLPERCENTAGE, CN2.NAMEVARIANTNO, CN2.REMARKS, CN2.CORRESPONDENCESENT, CN2.CORRESPONDENCERECEIVED, CN2.CORRESPSENT, CN2.CORRESPRECEIVED)
		     )", parameters);
        }

        async Task DeleteDuplicateCaseNames(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            delete CN1
		    from CASENAME CN1
		    where NAMENO=@to
		    and exists
		    (select 1
		     from CASENAME CN2
		     where CN2.CASEID  =CN1.CASEID
		     and   CN2.NAMETYPE=CN1.NAMETYPE
		     and   CN2.NAMENO  =CN1.NAMENO
		     and   CN2.SEQUENCE<CN1.SEQUENCE
		     and   CHECKSUM(CN1.CORRESPONDNAME, CN1.ADDRESSCODE, CN1.REFERENCENO, CN1.ASSIGNMENTDATE, CN1.COMMENCEDATE, CN1.EXPIRYDATE, CN1.BILLPERCENTAGE, CN1.NAMEVARIANTNO, CN1.REMARKS, CN1.CORRESPONDENCESENT, CN1.CORRESPONDENCERECEIVED, CN1.CORRESPSENT, CN1.CORRESPRECEIVED)
		         = CHECKSUM(CN2.CORRESPONDNAME, CN2.ADDRESSCODE, CN2.REFERENCENO, CN2.ASSIGNMENTDATE, CN2.COMMENCEDATE, CN2.EXPIRYDATE, CN2.BILLPERCENTAGE, CN2.NAMEVARIANTNO, CN2.REMARKS, CN2.CORRESPONDENCESENT, CN2.CORRESPONDENCERECEIVED, CN2.CORRESPSENT, CN2.CORRESPRECEIVED)
		     )", parameters);
        }

        async Task UpdateName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from c in _dbContext.Set<CaseName>()
                                         where c.NameId == @from.Id
                                         select c,
                                         _ => new CaseName {NameId = to.Id});
        }

        async Task UpdateInheritedName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from c in _dbContext.Set<CaseName>()
                                         where c.InheritedFromNameId == @from.Id
                                         select c,
                                         _ => new CaseName {InheritedFromNameId = to.Id});
        }

        async Task UpdateAttentionName(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            UPDATE CN 
		    SET CORRESPONDNAME =   case	when ( CN.DERIVEDCORRNAME = 0 ) then @to
						    when ( convert(bit,NT.COLUMNFLAGS&1)=0 and CN.NAMETYPE not in ('I','A') ) then NULL            
						    when ( AN.CONTACT is not null ) then AN.CONTACT            
						    else dbo.fn_GetDerivedAttnNameNo( CN.NAMENO, CN.CASEID, CN.NAMETYPE )   
					    end  
		    from CASENAME CN  
		    join NAMETYPE NT on (NT.NAMETYPE = CN.NAMETYPE)  
		    left join ASSOCIATEDNAME AN	on (AN.NAMENO = CN.INHERITEDNAMENO      
						    and AN.RELATIONSHIP = CN.INHERITEDRELATIONS      
						    and AN.RELATEDNAME = CN.NAMENO      
						    and AN.SEQUENCE = CN.INHERITEDSEQUENCE) 
		    WHERE CN.CORRESPONDNAME = @from", parameters);
        }
    }
}