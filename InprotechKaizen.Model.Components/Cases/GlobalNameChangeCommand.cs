using System.Collections.Generic;
using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases
{
    public interface IGlobalNameChangeCommand
    {
        Task PerformGlobalNameChange(IEnumerable<int> caseKeys,
                                               int userId,
                                               string nameType,
                                               int? newNameNo,
                                               int? keepRefNo = null,
                                               bool updateName = false,
                                               bool insertName = false,
                                               bool deleteName = false
                                               );
    }

    public class GlobalNameChangeCommand : IGlobalNameChangeCommand
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public GlobalNameChangeCommand(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public async Task PerformGlobalNameChange(
            IEnumerable<int> caseKeys,
            int userId,
            string nameType,
            int? newNameNo,
            int? keepRefNo = null,
            bool updateName = false,
            bool insertName = false,
            bool deleteName = false
            )
        {
            var culture = _preferredCultureResolver.Resolve();

            var cases = string.Join(",", caseKeys);
            var caseFilterXml =
                XElement.Parse($@"<csw_ListCase><FilterCriteriaGroup><FilterCriteria ID='1'><AccessMode>1</AccessMode><CaseKeys Operator='0'>{cases}</CaseKeys></FilterCriteria></FilterCriteriaGroup></csw_ListCase>");
            
            var inputParameters = new Parameters
            {
                {"@pnUserIdentityId", userId},
                {"@psCulture", culture},
                {"@psNameType", nameType},
                {"@pnNewNameNo", newNameNo},
                {"@pbUpdateName", updateName ? 1 : 0},
                {"@pbInsertName", insertName ? 1 : 0},
                {"@pbDeleteName", deleteName ? 1 : 0},
                {"@pnKeepReferenceNo", keepRefNo},
                {"@pbApplyInheritance", 1},
                {"@ptXMLFilterCriteria", caseFilterXml.ToString()}
            };

            using (var command = _dbContext.CreateStoredProcedureCommand(Inprotech.Contracts.StoredProcedures.GlobalNameChange, inputParameters))
            {
                await command.ExecuteNonQueryAsync();
            }
        }
    }
}
