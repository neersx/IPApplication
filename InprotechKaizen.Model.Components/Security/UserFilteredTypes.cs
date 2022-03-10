using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.StandingInstructions;

namespace InprotechKaizen.Model.Components.Security
{
    public interface IUserFilteredTypes
    {
        IQueryable<NameType> NameTypes();
        IQueryable<NumberType> NumberTypes();
        IEnumerable<TextType> TextTypes(bool forCaseOnly = false);
        IQueryable<InstructionType> InstructionTypes();
    }
    public class UserFilteredTypes : IUserFilteredTypes
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControlReader;

        public UserFilteredTypes(IDbContext dbContext, ISecurityContext securityContext, ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _siteControlReader = siteControlReader;
        }
        public IQueryable<NameType> NameTypes()
        {
            var nameTypes = _dbContext.Set<NameType>().Where(_ => (_.PickListFlags & 32) != 32).AsQueryable();
            if (!_securityContext.User.IsExternalUser) return nameTypes.OrderBy(_ => _.Name);
            {
                var clientNameTypes = _siteControlReader.Read<string>(SiteControls.ClientNameTypesShown);
                if (string.IsNullOrEmpty(clientNameTypes)) return nameTypes.OrderBy(_ => _.Name);
                var availableTypes = clientNameTypes.Split(',').Select(_ => _.Trim());
                nameTypes = nameTypes.Where(_ => availableTypes.Contains(_.NameTypeCode));
            }
            return nameTypes.OrderBy(_ => _.Name);
        }

        public IQueryable<NumberType> NumberTypes()
        {
            var numberTypes = _dbContext.Set<NumberType>().AsQueryable();

            if (_securityContext.User.IsExternalUser)
            {
                var clientNumberTypes = _siteControlReader.Read<string>(SiteControls.ClientNumberTypesShown);
                if (!string.IsNullOrEmpty(clientNumberTypes))
                {
                    var availableTypes = clientNumberTypes.Split(',').Select(_ => _.Trim());
                    numberTypes = numberTypes.Where(_ => availableTypes.Contains(_.NumberTypeCode));
                }
                else
                {
                    numberTypes = numberTypes.Where(_ => _.IssuedByIpOffice);
                }
            }

            return numberTypes.OrderBy(_ => _.Name);
        }

        public IEnumerable<TextType> TextTypes(bool forCaseOnly = false)
        {
            var textTypes = _dbContext.Set<TextType>().AsQueryable();

            var allowAllTypes = _siteControlReader.Read<bool>(SiteControls.AllowAllTextTypesForCases);

            if (_securityContext.User.IsExternalUser) 
            {
                var clientTextTypes = _siteControlReader.Read<string>(SiteControls.ClientTextTypes);
                if (!string.IsNullOrEmpty(clientTextTypes))
                {
                    var availableTypes = clientTextTypes.Split(',').Select(_ => _.Trim());
                    textTypes = textTypes.Where(_ => availableTypes.Contains(_.Id));
                }
            }

            if (forCaseOnly && !allowAllTypes)
                textTypes = textTypes.Where(_ => (_.UsedByFlag ?? 0) == 0);

            return textTypes.OrderBy(_ => _.TextDescription);
        }

        public IQueryable<InstructionType> InstructionTypes()
        {
            var instructionTypes = _dbContext.Set<InstructionType>().AsQueryable();

            if (_securityContext.User.IsExternalUser)
            {
                var clientInstructionTypes = _siteControlReader.Read<string>(SiteControls.ClientInstructionTypes);
                if (!string.IsNullOrEmpty(clientInstructionTypes))
                {
                    var availableTypes = clientInstructionTypes.Split(',').Select(_ => _.Trim());
                    instructionTypes = instructionTypes.Where(_ => availableTypes.Contains(_.Code));
                }
            }

            return instructionTypes.OrderBy(_ => _.Code);
        }
    }
}