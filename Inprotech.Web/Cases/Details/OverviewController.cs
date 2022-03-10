using System;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class OverviewController : ApiController
    {
        readonly IBasis _basis;
        readonly IAuditLogs _auditLogs;
        readonly ICaseCategories _caseCategories;
        readonly IClientNameDetails _clientNameDetails;
        readonly IDbContext _dbContext;
        readonly IPolicingStatusReader _policingStatusReader;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IPropertyTypes _propertyTypes;
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControls;
        readonly ICaseStatusReader _statusReader;
        readonly ISubTypes _subTypes;
        readonly ICaseHeaderDescription _caseHeaderDescription;
        readonly IDefaultCaseImage _defaultCaseImage;
        readonly ISubjectSecurityProvider _subjectSecurity;
        public OverviewController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, IBasis basis,
                                  ICaseStatusReader statusReader, IPropertyTypes propertyTypes, ICaseCategories caseCategories, ISubTypes subTypes,
                                  IPolicingStatusReader policingStatusReader, ISiteControlReader siteControls, ISecurityContext securityContext,
                                  IClientNameDetails clientNameDetails, ICaseHeaderDescription caseHeaderDescription, IDefaultCaseImage defaultCaseImage, ISubjectSecurityProvider subjectSecurity, IAuditLogs auditLogs)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _basis = basis;
            _statusReader = statusReader;
            _propertyTypes = propertyTypes;
            _caseCategories = caseCategories;
            _subTypes = subTypes;
            _policingStatusReader = policingStatusReader;
            _siteControls = siteControls;
            _securityContext = securityContext;
            _clientNameDetails = clientNameDetails;
            _caseHeaderDescription = caseHeaderDescription;
            _defaultCaseImage = defaultCaseImage;
            _subjectSecurity = subjectSecurity;
            _auditLogs = auditLogs;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [RegisterAccess]
        [Route("{caseKey:int}/overview")]
        public dynamic GetCaseOverview(int caseKey)
        {
            var culture = _preferredCultureResolver.Resolve();
            var @case = _dbContext.Set<Case>()
                                  .Include(c => c.PropertyType)
                                  .Include(c => c.PropertyType.IconImage)
                                  .Include(c => c.Country)
                                  .Include(c => c.Category)
                                  .Include(c => c.Type)
                                  .Include(c => c.SubType)
                                  .Include(c => c.Property)
                                  .Include(c => c.Property.RenewalStatus)
                                  .Include(c => c.CaseStatus)
                                  .Include(c => c.Family)
                                  .Include(c => c.Office)
                                  //.Include(c => c.MostRecentCaseLocation) TODO: Navigation property not defined, so usage below wouldnt have results
                                  .Include(c => c.ProfitCentre)
                                  //.Include(c => c.LocalClientFlag) TODO: Navigation property not defined, so usage below wouldnt have results
                                  .Include(c => c.EntitySize)
                                  .Include(c => c.TypeOfMark)
                                  //.Include(c => c.CaseEvents.Where(_ => _.EventNo == (short)KnownEvents.ApplicationFilingDate))
                                  .Include(c => c.CaseNames)
                                  .Include(c => c.CaseNames.Select(cn => cn.Name))
                                  .Include(c => c.CaseNames.Select(cn => cn.NameType))
                                  .SingleOrDefault(v => v.Id == caseKey);

            if (@case == null) return new HttpResponseMessage(HttpStatusCode.NotFound);

            var caseImage = _defaultCaseImage.For(@case.Id);
            var view = new Overview
            {
                CaseKey = @case.Id,
                Irn = @case.Irn,
                Title = DbFuncs.GetTranslation(@case.Title, null, @case.TitleTId, culture),
                PropertyTypeCode = @case.PropertyType?.Code,
                PropertyType = _propertyTypes.GetCasePropertyType(@case),
                PropertyTypeImageId = @case.PropertyType?.IconImage?.Id,
                Country = @case.Country == null ? null : DbFuncs.GetTranslation(@case.Country.Name, null, @case.Country.NameTId, culture),
                CaseCategory = _caseCategories.GetCaseCategory(@case),
                SubType = _subTypes.GetCaseSubType(@case),
                Basis = _basis.GetCaseBasis(@case),
                Status = _statusReader.GetCaseStatusSummary(@case)?.Name,
                CaseStatus = _statusReader.GetCaseStatusDescription(@case.CaseStatus),
                RenewalStatus = _statusReader.GetCaseStatusDescription(@case.Property?.RenewalStatus),
                OfficialNumber = @case.CurrentOfficialNumber,
                Family = @case.Family == null ? null : $"{DbFuncs.GetTranslation(@case.Family.Name, null, @case.Family.NameTId, culture)}{DisplayFamilyCode(@case.Family)}",
                CaseType = @case.Type == null ? null : DbFuncs.GetTranslation(@case.Type.Name, null, @case.Type.NameTId, culture),
                CaseOffice = @case.Office == null ? null : DbFuncs.GetTranslation(@case.Office.Name, null, @case.Office.NameTId, culture),
                FileLocation = @case.MostRecentCaseLocation()?.FileLocation == null ? null : DbFuncs.GetTranslation(@case.MostRecentCaseLocation().FileLocation.Name, null, @case.MostRecentCaseLocation().FileLocation.NameTId, culture),
                ProfitCentre = @case.ProfitCentre == null ? null : DbFuncs.GetTranslation(@case.ProfitCentre.Name, null, @case.ProfitCentre.NameTId, culture),
                LocalClientFlag = @case.LocalClientFlag.HasValue && @case.LocalClientFlag.Value == 1m,
                EntitySize = @case.EntitySize == null ? null : DbFuncs.GetTranslation(@case.EntitySize.Name, null, @case.EntitySize.NameTId, culture),
                TypeOfMark = @case.TypeOfMark == null ? null : DbFuncs.GetTranslation(@case.TypeOfMark.Name, null, @case.TypeOfMark.NameTId, culture),
                NumberInSeries = @case.NoInSeries,
                Classes = @case.LocalClasses,
                FirstApplicant = @case.FirstApplicant(),
                Instructor = @case.ClientName(),
                ApplicationFilingDate = @case.CaseEvents.FirstOrDefault(_ => _.EventNo == (short)KnownEvents.ApplicationFilingDate)?.EventDate,
                ImageKey = caseImage?.ImageId,
                ImageDescription = caseImage?.CaseImageDescription,
                IsRegistered = @case.CaseStatus?.IsRegistered ?? false,
                IsPending = @case.CaseStatus == null || @case.CaseStatus.IsLive && !@case.CaseStatus.IsRegistered,
                IsDead = @case.CaseStatus != null && !@case.CaseStatus.IsLive,
                PolicingStatus = _securityContext.User.IsExternalUser ? null : _policingStatusReader.Read(@case.Id),
                DisplayNameVariants = _siteControls.Read<bool>(SiteControls.NameVariant),
                CaseDefaultDescription = _caseHeaderDescription.For(@case.Irn),
                AllowSubClass = @case.PropertyType.AllowSubClass == 2,
                UsesDefaultCountryForClasses = IsUsesDefaultCountryForClasses(@case.PropertyTypeId, @case.CountryId),
                AllowSubClassWithoutItem = @case.PropertyType.AllowSubClass == 1,
                HasAccessToAttachmentSubject = _subjectSecurity.HasAccessToSubject(ApplicationSubject.Attachments),
                HasBillPercentageDisplayed = @case.CaseNames.Where(_ => _.NameType.IsBillPercentDisplayed).Select(_ => _.NameType.NameTypeCode).Distinct().ToList(),
                HasCaseEventAuditingConfigured = _auditLogs.HasAuditEnabled<CaseEventILog>()
            };

            var workingAttorney = @case.WorkingAttorneyName();
            view.Staff = workingAttorney == null
                ? new NameDetail()
                : new NameDetail
                {
                    Name = workingAttorney.Name.FormattedNameOrNull(),
                    NameCode = workingAttorney.Name.NameCode,
                    NameKey = workingAttorney.NameId,
                    NameType = KnownNameTypes.StaffMember,
                    ShowCode = workingAttorney.NameType.ToShowNameCode()
                };

            if (_securityContext.User.IsExternalUser)
            {
                var clientAccessDetails = _clientNameDetails.GetDetails(@case);

                view.YourReference = clientAccessDetails?.Reference;
                if (clientAccessDetails.ExternalContact != null)
                {
                    view.ClientMainContact = new NameDetail
                    {
                        Name = clientAccessDetails.ExternalContact.Formatted(),
                        NameKey = clientAccessDetails.ExternalContact.Id,
                        NameCode = clientAccessDetails.ExternalContact.NameCode
                    };
                }

                if (clientAccessDetails.FirmContact != null)
                {
                    view.OurContact = new NameDetail
                    {
                        Name = clientAccessDetails.FirmContact.Formatted(),
                        NameKey = clientAccessDetails.FirmContact.Id,
                        NameCode = clientAccessDetails.FirmContact.NameCode,
                        NameType = clientAccessDetails.FirmContactNameType,
                        ShowCode = clientAccessDetails.FirmContactNameTypeShowCode
                    };
                }
            }

            return view;
        }

        bool IsUsesDefaultCountryForClasses(string propertyTypeId, string countryId)
        {
            return !_dbContext.Set<TmClass>().Any(_ => _.PropertyType == propertyTypeId && _.CountryCode == countryId);
        }

        static string DisplayFamilyCode(Family fam)
        {
            var id = string.Equals(fam.Name?.Trim() ?? string.Empty, fam.Id.Trim(), StringComparison.InvariantCultureIgnoreCase) ? null : $" {{{fam.Id}}}";
            return id;
        }
    }
}