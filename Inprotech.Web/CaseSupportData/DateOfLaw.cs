using System;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Policy;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.CaseSupportData
{
    public interface IDateOfLaw
    {
        DateTime? GetDefaultDateOfLaw(int caseId, string actionId);
    }

    public interface IFormatDateOfLaw
    {
        string AsId(DateTime dateOfLaw);
        string Format(DateTime dateOfLaw);
    }

    public class DateOfLaw : IDateOfLaw
    {
        readonly IDbContext _dbContext;
        public DateOfLaw(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public DateTime? GetDefaultDateOfLaw(int caseId, string actionId)
        {
            return _dbContext.GetDefaultDateOfLaw(caseId, actionId);
        }
    }

    public class FormatDateOfLaw : IFormatDateOfLaw
    {
        readonly ISiteDateFormat _siteDateFormat;
        readonly IPreferredCultureResolver _cultureResolver;

        public FormatDateOfLaw(ISiteDateFormat siteDateFormat, IPreferredCultureResolver cultureResolver)
        {
            _siteDateFormat = siteDateFormat;
            _cultureResolver = cultureResolver;
        }
        public string AsId(DateTime dateOfLaw)
        {
            return dateOfLaw.ToString();
        }

        public string Format(DateTime dateOfLaw)
        {
            var dateFormat =_siteDateFormat.Resolve(_cultureResolver.Resolve());
            return dateOfLaw.ToString(dateFormat);
        }
    }
}
