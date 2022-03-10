using System.Linq;
using Inprotech.Web.Characteristics;
using Inprotech.Web.Search;
using Inprotech.Web.Search.Case;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Configuration.Rules.ValidCharacteristic
{

    public interface IValidatedProgramCharacteristic
    {
        ValidatedCharacteristic GetDefaultProgram();
        ValidatedCharacteristic GetProgram(string programId);
    }

    public class ValidatedProgramCharacteristic : IValidatedProgramCharacteristic
    {
        readonly IListPrograms _listCasePrograms;
        readonly IDbContext _dbContext;
        public ValidatedProgramCharacteristic(IListPrograms listCasePrograms, IDbContext dbContext)
        {
            _listCasePrograms = listCasePrograms;
            _dbContext = dbContext;
        }

        public ValidatedCharacteristic GetDefaultProgram()
        {
            var programName = _listCasePrograms.GetDefaultCaseProgram();
            if (string.IsNullOrWhiteSpace(programName))
                return null;

            var program = _dbContext.Set<Program>().FirstOrDefault(_ => _.Id == programName);
            return program == null ? null : new ValidatedCharacteristic(program.Id, program.Name);
        }

        public ValidatedCharacteristic GetProgram(string programName)
        {
            if (string.IsNullOrWhiteSpace(programName))
                return null;

            var program = _dbContext.Set<Program>().FirstOrDefault(_ => _.Id == programName);
            return program == null ? null : new ValidatedCharacteristic(program.Id, program.Name);
        }
    }
}
