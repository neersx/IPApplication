using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Search
{
    public interface IListPrograms
    {
        string GetDefaultCaseProgram();
        string GetDefaultNameProgram();

        IEnumerable<ProfileProgramModel> GetCasePrograms();
        IEnumerable<ProfileProgramModel> GetNamePrograms();
    }

    public class ListPrograms : IListPrograms
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControlReader;
        readonly IStaticTranslator _staticTranslator;

        public ListPrograms(IDbContext dbContext, ISecurityContext securityContext, ISiteControlReader siteControlReader, IPreferredCultureResolver preferredCultureResolver, IStaticTranslator staticTranslator)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _siteControlReader = siteControlReader;
            _preferredCultureResolver = preferredCultureResolver;
            _staticTranslator = staticTranslator;
        }

        public string GetDefaultCaseProgram()
        {
            var profileId = _securityContext.User?.Profile?.Id;
            var siteControl = _securityContext.User != null && _securityContext.User.IsExternalUser ? SiteControls.CaseProgramForClientAccess : SiteControls.CaseScreenDefaultProgram;

            return _dbContext.Set<ProfileAttribute>()
                             .FirstOrDefault(_ => _.ProfileId == profileId && _.InternalAttributeId == (int) ProfileAttributeType.DefaultCaseProgram)?.Value
                   ?? _siteControlReader.Read<string>(siteControl);
        }

        public string GetDefaultNameProgram()
        {
            var profileId = _securityContext.User?.Profile?.Id;
            var siteControl = SiteControls.NameScreenDefaultProgram;

            return _dbContext.Set<ProfileAttribute>()
                             .FirstOrDefault(_ => _.ProfileId == profileId && _.InternalAttributeId == (int) ProfileAttributeType.DefaultNameProgram)?.Value
                   ?? _siteControlReader.Read<string>(siteControl);
        }

        public IEnumerable<ProfileProgramModel> GetCasePrograms()
        {
            var defaultProgram = GetDefaultCaseProgram();
            return GetPrograms("C", defaultProgram);
        }

        public IEnumerable<ProfileProgramModel> GetNamePrograms()
        {
            var defaultProgram = GetDefaultNameProgram();
            return GetPrograms("N", defaultProgram);
        }

        IEnumerable<ProfileProgramModel> GetPrograms(string group, string defaultProgram)
        {
            var culture = _preferredCultureResolver.Resolve();
            var profileId = _securityContext.User?.Profile?.Id;
            var programs = _dbContext.Set<ProfileProgram>()
                                     .Where(_ => _.ProfileId == profileId && _.Program.ProgramGroup == group && _.ProgramId != defaultProgram)
                                     .Select(p => new ProfileProgramModel
                                     {
                                         Id = p.ProgramId,
                                         Name = DbFuncs.GetTranslation(p.Program.Name, null, p.Program.Name_TID, culture),
                                         IsDefault = false
                                     }).ToList();

            var cp = _dbContext.Set<Program>().FirstOrDefault(_ => _.Id == defaultProgram);
            if (cp == null) return programs;

            var defaultString = _staticTranslator.Translate("bulkactionsmenu.default", _preferredCultureResolver.ResolveAll());

            var program = new ProfileProgramModel(cp.Id, DbFuncs.GetTranslation(cp.Name, null, cp.Name_TID, culture) + " " + defaultString, true);
            programs.Add(program);
            return programs.OrderBy(_ => _.Name);
        }
    }

    public class ProfileProgramModel
    {
        public ProfileProgramModel()
        {
        }

        public ProfileProgramModel(string id, string name, bool isDefault)
        {
            Id = id;
            Name = name;
            IsDefault = isDefault;
        }

        public string Id { get; set; }
        public string Name { get; set; }
        public bool IsDefault { get; set; }
    }
}