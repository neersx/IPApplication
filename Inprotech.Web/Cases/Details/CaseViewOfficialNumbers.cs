using System;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json;

namespace Inprotech.Web.Cases.Details
{
    public interface ICaseViewOfficialNumbers
    {
        IQueryable<OfficialNumbersData> IpOfficeNumbers(int caseId);

        IQueryable<OfficialNumbersData> OtherNumbers(int caseId);
    }

    class CaseViewOfficialNumbers : ICaseViewOfficialNumbers
    {
        readonly IDbContext _dbContext;
        readonly IUserFilteredTypes _userFilteredTypes;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public CaseViewOfficialNumbers(IDbContext dbContext, IUserFilteredTypes userFilteredTypes, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _userFilteredTypes = userFilteredTypes;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public IQueryable<OfficialNumbersData> IpOfficeNumbers(int caseId)
        {
            return OfficialNumbers(caseId).Where(_ => _.IssuedByIpOffice);
        }

        public IQueryable<OfficialNumbersData> OtherNumbers(int caseId)
        {
            return OfficialNumbers(caseId).Where(_ => !_.IssuedByIpOffice);
        }

        IQueryable<OfficialNumbersData> OfficialNumbers(int caseId)
        {
            var culture = _preferredCultureResolver.Resolve();
            var officialNumbers = _dbContext.Set<OfficialNumber>().Where(_ => _.CaseId == caseId);
            //var caseEvents = from c in _dbContext.Set<CaseEvent>().Where(_ => _.CaseId == caseId)
            //                 join cMax in _dbContext.Set<CaseEvent>().Where(_ => _.CaseId == caseId)
            //                                        .GroupBy(_ => new { _.CaseId, _.EventNo })
            //                                        .Select(g => new { g.Key, Cycle = (short?)g.Max(_ => _.Cycle) })
            //                     on new { c.CaseId, c.EventNo } equals new { cMax.Key.CaseId, cMax.Key.EventNo } into cMax1
            //                 from cMax in cMax1.DefaultIfEmpty()
            //                 where c.Cycle == (cMax.Cycle ?? 1)
            //                 select new
            //                 {
            //                     c.CaseId,
            //                     c.EventNo,
            //                     c.Cycle,
            //                     c.EventDate
            //                 };

            var numberTypes = _userFilteredTypes.NumberTypes();

            return (from o in officialNumbers
                    join fnt in numberTypes on o.NumberTypeId equals fnt.NumberTypeCode
                    //join ce in caseEvents on fnt.RelatedEventId equals ce.EventNo into ce1
                    //from ce in ce1.DefaultIfEmpty()
                    select new OfficialNumbersData
                    {
                        CaseId = o.CaseId,
                        NumberTypeDescription = DbFuncs.GetTranslation(fnt.Name, null, fnt.NameTId, culture),
                        OfficialNumber = o.Number,
                        //EventDate = ce.EventDate,
                        DateInForce = o.DateEntered,// != null ? o.DateEntered : ce.EventDate,
                        IsCurrent = o.IsCurrent == 1,
                        IssuedByIpOffice = fnt.IssuedByIpOffice,
                        DisplayPriority = fnt.DisplayPriority,
                        DocItemId = fnt.DocItemId
                    }).OrderBy(_ => _.DisplayPriority).ThenBy(_ => _.NumberTypeDescription).ThenByDescending(_ => _.DateInForce).ThenByDescending(_ => _.IsCurrent).ThenBy(_ => _.OfficialNumber);
        }
    }

    public class OfficialNumbersData
    {
        public int CaseId { get; set; }
        public string NumberTypeDescription { get; set; }
        public string OfficialNumber { get; set; }
        public DateTime? EventDate { get; set; }
        public DateTime? DateInForce { get; set; }
        public bool? IsCurrent { get; set; }
        public Uri ExternalInfoLink { get; set; }

        [JsonIgnore]
        public bool IssuedByIpOffice { get; set; }
        [JsonIgnore]
        public short DisplayPriority { get; set; }
        [JsonIgnore]
        public int? DocItemId { get; set; }
    }

}