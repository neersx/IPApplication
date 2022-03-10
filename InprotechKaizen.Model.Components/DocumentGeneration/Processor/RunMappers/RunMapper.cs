using System.Data;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.DocumentGeneration.Processor.RunMappers
{
    public abstract class RunMapper
    {
        public const char PARAMETER_SEPARATOR = '^';
        protected IDbContext _dbContext;
        protected readonly ISecurityContext _securityContext;
        protected readonly IPreferredCultureResolver _preferredCultureResolver;

        public RunMapper(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public abstract DataSet Execute(string sqlQueryOrStoredProcedure, string parameters, string entryPointValue, RunDocItemParams runDocItemParams);
    }
}
