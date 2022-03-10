using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.Configuration.Jurisdictions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.CriticalDates;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.SummaryPreview
{
    public interface ICaseHeaderInfo
    {
        Task<(CaseSummary Summary, IEnumerable<CaseSummaryName> Names)> Retrieve(int userIdentityId, string culture, int caseKey);
    }

    public class CaseHeaderInfo : ICaseHeaderInfo
    {
        readonly ICaseHeaderPartial _caseHeader;
        readonly IDbContext _dbContext;
        readonly INextRenewalDatesResolver _nextRenewalDatesResolver;
        readonly IDefaultCaseImage _defaultCaseImage;

        public CaseHeaderInfo(
            IDbContext dbContext,
            ICaseHeaderPartial caseHeader,
            INextRenewalDatesResolver nextRenewalDatesResolver,
            IDefaultCaseImage defaultCaseImage)
        {
            _dbContext = dbContext;
            _caseHeader = caseHeader;
            _nextRenewalDatesResolver = nextRenewalDatesResolver;
            _defaultCaseImage = defaultCaseImage;
        }

        public async Task<(CaseSummary Summary, IEnumerable<CaseSummaryName> Names)> Retrieve(int userIdentityId, string culture, int caseKey)
        {
            var caseHeaderImage = _defaultCaseImage.For(caseKey);

            var interimCase = await (from c in _dbContext.Set<Case>()
                                     join ce in _dbContext.Set<CaseEvent>() on new {EventNo = (int) KnownEvents.InstructionsReceivedDateForNewCase, CaseId = c.Id, Cycle = (short) 1} equals new {ce.EventNo, ce.CaseId, ce.Cycle} into ce1
                                     from ce in ce1.DefaultIfEmpty()
                                     where c != null && c.Id == caseKey
                                     select new
                                     {
                                         Case = c,
                                         CaseTypeDescription = DbFuncs.GetTranslation(c.Type.Name, null, c.Type.NameTId, culture),
                                         DateOfInstruction = ce != null ? ce.EventDate : null,
                                         ShowYear = c.PropertyType.Code != "T",
                                         TypeOfMark = c.PropertyType.Code == "T" ? DbFuncs.GetTranslation(c.TypeOfMark.Name, null, c.TypeOfMark.NameTId, culture) : null,
                                         IsTrademark = c.PropertyType.Code == "T",
                                         OfficialNumber = c.CurrentOfficialNumber
                                     }).SingleOrDefaultAsync();

            var result = await _caseHeader.Retrieve(userIdentityId, culture, caseKey);

            var nextRenewal = await _nextRenewalDatesResolver.Resolve(caseKey, null);

            var instructorReference = result.Names?.FirstOrDefault(_ => _.NameTypeKey == "I")?.NameReference;

            return (new CaseSummary
            {
                CaseKey = result.CaseKey,
                Title = result.Title,
                CountryName = result.CountryName,
                PropertyTypeDescription = result.PropertyTypeDescription,
                CaseCategoryDescription = result.CaseCategoryDescription,
                SubTypeDescription = result.SubTypeDescription,
                FileLocation = result.FileLocation,
                CaseOffice = result.CaseOffice,
                CaseStatusDescription = result.CaseStatusDescription,
                RenewalStatusDescription = result.RenewalStatusDescription,
                RenewalInstruction = result.RenewalInstruction,
                IsCRM = result.IsCRM,
                Classes = result.Classes.Sort(),
                AgeOfCase = nextRenewal?.AgeOfCase,
                Irn = interimCase.Case.Irn,
                CaseTypeDescription = interimCase.CaseTypeDescription,
                DateOfInstruction = interimCase.DateOfInstruction,
                ShowYear = interimCase.ShowYear,
                ImageKey = caseHeaderImage?.ImageId,
                ImageTitle = caseHeaderImage?.CaseImageDescription,
                TypeOfMark = interimCase.TypeOfMark,
                TotalClasses = result.TotalClasses,
                InstructorReference = instructorReference,
                IsTrademark = interimCase.IsTrademark,
                OfficialNumber = interimCase.OfficialNumber,
                BasisDescription = result.BasisDescription
            }, result.Names);
        }
    }

    public class CaseSummary
    {
        public int CaseKey { get; set; }

        public string Title { get; set; }

        public string CaseStatusDescription { get; set; }

        public string RenewalStatusDescription { get; set; }

        public string CountryName { get; set; }

        public string PropertyTypeDescription { get; set; }

        public string CaseCategoryDescription { get; set; }

        public string SubTypeDescription { get; set; }

        public string FileLocation { get; set; }

        public string CaseOffice { get; set; }

        public string RenewalInstruction { get; set; }

        public bool? IsCRM { get; set; }

        public string Irn { get; set; }

        public string CaseTypeDescription { get; set; }

        public short? AgeOfCase { get; set; }

        public DateTime? DateOfInstruction { get; set; }

        public bool ShowYear { get; set; }

        public int? ImageKey { get; set; }

        public string Basis { get; set; }

        public string StatusSummary { get; set; }

        public string ImageTitle { get; set; }

        public string Classes { get; set; }

        public string OfficialNumber { get; set; }

        public string InstructorReference { get; set; }

        public string BasisDescription { get; set; }

        public string TypeOfMark { get; set; }

        public int? TotalClasses { get; set; }

        public bool IsTrademark { get; set; }
    }
}