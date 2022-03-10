using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Globalization;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Integration.ExternalApplications.Crm.Request;
using Inprotech.Integration.Filters;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Components.Configuration.Extensions;
using InprotechKaizen.Model.Components.Names.Validation;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.ExternalApplications.Crm
{
    [RequiresApiKey(ExternalApplicationName.Trinogy, true)]
    [RequiresLicense(LicensedModule.CrmWorkBench)]
    [RequiresLicense(LicensedModule.MarketingModule)]
    [RoutePrefix("crm")]
    public class CrmController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ICaseAuthorization _caseAuthorization;
        readonly INameAccessSecurity _nameAccessSecurity;
        readonly INameAttributeLoader _nameAttributeLoader;
        readonly ICrmValidator _crmValidator;
        readonly ICrmContactProcessor _crmContactProcessor;
        readonly INameValidator _nameValidator;
        readonly ITransactionRecordal _transactionRecordal;
        readonly IContactActivityProcessor _activityProcessor;
        readonly ISecurityContext _securityContext;

        const string Office = "OFFICE";

        public CrmController(IDbContext dbContext, 
            ICaseAuthorization caseAuthorization,
            INameAccessSecurity nameAccessSecurity, INameAttributeLoader nameAttributeLoader,
            ICrmValidator crmValidator, ICrmContactProcessor crmContactProcessor, INameValidator nameValidator,
            ITransactionRecordal transactionalRecordal,
            IContactActivityProcessor activityProcessor, ISecurityContext securityContext)
        {
            _dbContext = dbContext;
            _caseAuthorization = caseAuthorization;
            _securityContext = securityContext;
            _nameAccessSecurity = nameAccessSecurity;
            _nameAttributeLoader = nameAttributeLoader;
            _crmValidator = crmValidator;
            _crmContactProcessor = crmContactProcessor;
            _nameValidator = nameValidator;
            _transactionRecordal = transactionalRecordal;
            _activityProcessor = activityProcessor;
        }

        [HttpGet]
        [Route("property/{propertyName}/cases")]
        [HandleNullArgument]
        public async Task<IEnumerable<CrmCase>> ListCases(string propertyName)
        {
            var propertyTypeCode = PropertyTypeCode(propertyName);
            var cases =
                _dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                    .Where(@case => @case.PropertyType.Code.Equals(propertyTypeCode)
                                    && @case.PropertyType.CrmOnly.HasValue && @case.PropertyType.CrmOnly.Value
                                    && @case.CaseStatus != null
                                    && @case.CaseStatus.LiveFlag == 1m).ToList();

            return !cases.Any() ? Enumerable.Empty<CrmCase>() : await LoadCrmDetailsWithSecurityCheck(cases);
        }

        string PropertyTypeCode(string propertyName)
        {
            var siteControls = string.Empty;
            CrmPropertyType crmType;
            if (!Enum.TryParse(propertyName, true, out crmType))
                HttpResponseExceptionHelper.RaiseBadRequest(ErrorTypeCode.InvalidParameter.ToString());

            switch (crmType)
            {
                case CrmPropertyType.Campaign:
                    siteControls = SiteControls.PropertyTypeCampaign;
                    break;
                case CrmPropertyType.Marketingevent:
                    siteControls = SiteControls.PropertyTypeMarketingEvent;
                    break;
                case CrmPropertyType.Opportunity:
                    siteControls = SiteControls.PropertyTypeOpportunity;
                    break;
            }

            var propertyTypeSiteControl = _dbContext.Set<SiteControl>().First(sc => sc.ControlId == siteControls);
            if (string.IsNullOrEmpty(propertyTypeSiteControl.StringValue))
                HttpResponseExceptionHelper.RaiseBadRequest(ErrorTypeCode.SitecontrolNotSet.ToString());

            return propertyTypeSiteControl.StringValue;
        }

        async Task<IEnumerable<CrmCase>> LoadCrmDetailsWithSecurityCheck(List<InprotechKaizen.Model.Cases.Case> crmCases)
        {
            var currentUser = _securityContext.User;

            var permissions = await _caseAuthorization.GetInternalUserAccessPermissions(crmCases.Select(o => o.Id),
                Convert.ToInt32(currentUser.Id));

            return crmCases.Where(crmcase =>
                permissions.ContainsKey(crmcase.Id) &&
                (permissions[crmcase.Id] & AccessPermissionLevel.Select) ==
                AccessPermissionLevel.Select)
                .Select(
                    @case =>
                        new CrmCase
                        {
                            CaseId = @case.Id,
                            Irn = @case.Irn,
                            CaseCategoryId = @case.Category != null ? @case.Category.CaseCategoryId : string.Empty,
                            CaseCategoryDescription = @case.Category != null ? @case.Category.Name : string.Empty,
                            PropertyTypeId = @case.PropertyType.Code,
                            PropertyName = @case.PropertyType.Name,
                            StaffName = @case.WorkingAttorney(),
                            Title = @case.Title
                        }).OrderBy(@case => @case.Irn);
        }

        [HttpPut]
        [Route("case/{caseId}/contact/{nameId}/response")]
        [HandleNullArgument]
        public async Task<HttpResponseMessage> UpdateResponse(int caseId, int nameId, MarketingResponse marketingResponse)
        {
            TableCode response = null;
            if (marketingResponse != null && marketingResponse.ResponseId.HasValue)
            {
                response =
                    _dbContext.Set<TableCode>()
                        .SingleOrDefault(tc => tc.Id.Equals(marketingResponse.ResponseId.Value)
                                               && tc.TableTypeId.Equals((short)ProtectedTableTypes.MarketingActivityResponse));

                if (response == null)
                    HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.ResponseCodeDoesNotExist.ToString());
            }

            var caseName = await MarketingActivityContactName(caseId, nameId);

            if (response != null)
                caseName.IsCorrespondenceSent = true;

            caseName.SetCorrespondenceReceived(response);

            _dbContext.SaveChanges();

            return new HttpResponseMessage(HttpStatusCode.OK);
        }

        [HttpPut]
        [Route("case/{caseId}/contact/{nameId}/correspondence")]
        [HandleNullArgument]
        public async Task<HttpResponseMessage> UpdateCorrespondence(int caseId, int nameId, CrmCorrespondence crmCorrespondence)
        {
            var caseName = await MarketingActivityContactName(caseId, nameId);

            if (crmCorrespondence != null)
                caseName.IsCorrespondenceSent = crmCorrespondence.CorrespondenceSent;
            _dbContext.SaveChanges();

            return new HttpResponseMessage(HttpStatusCode.OK);
        }

        async Task<CaseName> MarketingActivityContactName(int caseId, int nameId)
        {
            var @case = _dbContext.Set<InprotechKaizen.Model.Cases.Case>().SingleOrDefault(c => c.Id.Equals(caseId));

            if (@case == null) HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.CaseDoesntExist.ToString());

            _crmValidator.ValidateCrmCaseSecurity(@case);

            var r = await _caseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Update);
            if (r.IsUnauthorized)
                throw new DataSecurityException(ErrorTypeCode.NoRowaccessForCase.ToString().CamelCaseToUnderscore());

            var caseName =
                _dbContext.Set<CaseName>()
                    .Include(x => x.CorrespondenceReceived)
                    .SingleOrDefault(cn => cn.CaseId.Equals(caseId)
                                           && cn.NameId.Equals(nameId)
                                           && cn.Case.PropertyType.CrmOnly.HasValue &&
                                           cn.Case.PropertyType.CrmOnly.Value
                                           && cn.NameType.NameTypeCode.Equals(KnownNameTypes.Contact));

            if (caseName == null)
                HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.ContactDoesNotExist.ToString());

            return caseName;
        }

        [HttpGet]
        [Route("case/{caseId}/contacts")]
        public async Task<IEnumerable<CrmContact>> ListContacts(int caseId, bool listAttributes = false)
        {
            var @case = _dbContext.Set<InprotechKaizen.Model.Cases.Case>().SingleOrDefault(x => x.Id == caseId);
            if (@case == null) HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.CaseDoesntExist.ToString());

            var permissions = await _caseAuthorization.GetInternalUserAccessPermissions(
                new List<int> {caseId},
                Convert.ToInt32(_securityContext.User.Id));

            if (!permissions.ContainsKey(caseId) ||
                (permissions[caseId] & AccessPermissionLevel.Select) != AccessPermissionLevel.Select)
                return Enumerable.Empty<CrmContact>();

            var caseNames =
                _dbContext.Set<CaseName>()
                    .Where(cn => cn.CaseId == caseId && cn.NameType.NameTypeCode == KnownNameTypes.Contact)
                    .ToList();

            return !caseNames.Any()
                ? Enumerable.Empty<CrmContact>()
                : caseNames
                    .Select(
                        cn =>
                            new CrmContact(cn.Name, cn.GetContactDetail(_dbContext), cn.CorrespondenceReceived,
                                cn.IsCorrespondenceSent)
                            {
                                NameAttributes = listAttributes ? ListAttributes(cn.NameId) : null
                            })
                    .OrderBy(contact => contact.Name).ToList();
        }

        [HttpDelete]
        [Route("case/{caseId}/contact/{nameId}")]
        public async Task<HttpResponseMessage> RemoveContact(int caseId, int nameId)
        {
            var caseName = await MarketingActivityContactName(caseId, nameId);

            _dbContext.Set<CaseName>().Remove(caseName);
            _dbContext.SaveChanges();

            return new HttpResponseMessage(HttpStatusCode.OK);
        }

        [HttpPut]
        [Route("case/{caseId}/contact/{nameId}")]
        public async Task<HttpResponseMessage> AddContact(int caseId, int nameId)
        {
            var name = _dbContext.Set<Name>().SingleOrDefault(x => x.Id == nameId);
            if (name == null)
                HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.ContactDoesNotExist.ToString());

            var @case = _dbContext.Set<InprotechKaizen.Model.Cases.Case>().SingleOrDefault(x => x.Id == caseId);
            if (@case == null) HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.CaseDoesntExist.ToString());

            _crmValidator.ValidateCrmCaseSecurity(@case);

            var r = await _caseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Update);
            if (r.IsUnauthorized) throw new DataSecurityException(ErrorTypeCode.NoRowaccessForCase.ToString().CamelCaseToUnderscore());

            var caseName = _dbContext.Set<CaseName>()
                .SingleOrDefault(x => x.CaseId == caseId && x.NameId == nameId && x.NameTypeId == KnownNameTypes.Contact);
            if (caseName != null)
                HttpResponseExceptionHelper.RaiseFound(ErrorTypeCode.ContactAlreadyExist.ToString());

            AddCaseName(@case, name);

            return new HttpResponseMessage(HttpStatusCode.OK);
        }

        void AddCaseName(InprotechKaizen.Model.Cases.Case @case, Name name, bool addNameTypeClassification = true)
        {
            using (var txScope = _dbContext.BeginTransaction())
            {
                _transactionRecordal.RecordTransactionFor(@case, CaseTransactionMessageIdentifier.AmendedCase);

                var existingContact = _dbContext.Set<CaseName>()
                    .Where(x => x.CaseId == @case.Id && x.NameTypeId == KnownNameTypes.Contact);

                var maxSequence = -1;
                if (existingContact.Any())
                    maxSequence = existingContact.Max(x => x.Sequence);

                var contactNameType = _dbContext.Set<NameType>()
                    .First(x => x.NameTypeCode == KnownNameTypes.Contact);

                var caseName = new CaseName(@case, contactNameType, name, (short) (maxSequence + 1));
                _dbContext.Set<CaseName>().Add(caseName);

                if (addNameTypeClassification)
                {
                    var nameTypeClassification = _dbContext.Set<NameTypeClassification>()
                        .SingleOrDefault(x => x.NameId == caseName.NameId && x.NameTypeId == caseName.NameTypeId);
                    if (nameTypeClassification != null)
                    {
                        nameTypeClassification.IsAllowed = 1;
                    }
                    else
                    {
                        nameTypeClassification = new NameTypeClassification(caseName.Name, caseName.NameType)
                                                 {
                                                     IsAllowed = 1
                                                 };
                        _dbContext.Set<NameTypeClassification>().Add(nameTypeClassification);
                    }
                }
                _dbContext.SaveChanges();

                txScope.Complete();
            }
        }

        [HttpGet]
        [Route("contact/{nameId}/attributes")]
        [HandleNullArgument]
        public NameAttributes ListAttributes(int nameId)
        {
            var name = _dbContext.Set<Name>().SingleOrDefault(n => n.Id == nameId);

            if (name == null)
                HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.ContactDoesNotExist.ToString());

            if (!_crmValidator.IsCrmName(name) || !_nameAccessSecurity.CanView(name))
                return new NameAttributes();

            var selectionTypes = _nameAttributeLoader.ListAttributeTypes(name);

            var modifiableTableTypes =
                selectionTypes.Where(st => st.ModifiableByService)
                    .Select(st => st.TableType).ToList();

            var selectedNameAttributes = _nameAttributeLoader.ListNameAttributeData(name);

            var availableNameAttributes =
                modifiableTableTypes.Where(mtt => mtt.DatabaseTable.ToUpper() != Office).Select(
                    mtt => new AttributeType(mtt.Id, mtt.Name, mtt.TableCodes))
                    .ToList();

            var officeAttribute =
                modifiableTableTypes.FirstOrDefault(mtt => mtt.DatabaseTable.ToUpper() == Office);

            if (officeAttribute != null)
            {
                var officeAttributeType = new AttributeType(officeAttribute.Id, officeAttribute.Name,
                    Enumerable.Empty<TableCode>());

                _dbContext.Set<Office>()
                    .Select(off => off)
                    .ToList()
                    .ForEach(oc => officeAttributeType.Attributes.Add(new Attribute
                                                                      {
                                                                          AttributeId = oc.Id,
                                                                          AttributeDescription = oc.Name,
                                                                          AttributeTypeId =
                                                                              officeAttributeType.AttributeTypeId
                                                                      }));

                availableNameAttributes.Add(officeAttributeType);
            }

            var attributes = new NameAttributes
                             {
                                 AvailableNameAttributes =
                                     availableNameAttributes.OrderBy(at => at.AttributeTypeDescription).ToList(),
                                 SelectedNameAttributes =
                                     selectedNameAttributes.Where(
                                         sn => modifiableTableTypes.Select(mtt => mtt.Id).Contains(sn.AttributeTypeId))
                                     .ToList()
                             };

            return attributes;
        }

        [HttpPut]
        [Route("contact/{nameId}/attributes")]
        [HandleNullArgument]
        public HttpResponseMessage UpdateNameAttributes(int nameId, CrmAttributes crmAttributes)
        {
            var name = _dbContext.Set<Name>().SingleOrDefault(n => n.Id == nameId);

            if (name == null)
                HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.ContactDoesNotExist.ToString());

            if (crmAttributes.NameAttributes == null)
                HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.NameattributesDoesntExist.ToString());

            if (!_crmValidator.IsCrmName(name) || !_nameAccessSecurity.CanUpdate(name))
                throw new DataSecurityException(ErrorTypeCode.NoRowaccessForName.ToString().CamelCaseToUnderscore());

            using (var tx = _dbContext.BeginTransaction())
            {
                var availableSelectionTypes = _nameAttributeLoader.ListAttributeTypesModifiableByExternalSystem(name);
                var modifiableTableTypes = availableSelectionTypes.Select(st => st.TableTypeId).ToList();

                var selectedNameAttributes = _nameAttributeLoader.ListNameAttributeData(name)
                    .Where(sn => modifiableTableTypes.Contains(sn.AttributeTypeId))
                    .ToList();

                var givenAttributes = crmAttributes.NameAttributes
                    .Where(na => modifiableTableTypes.Contains(na.AttributeTypeId))
                    .ToList();

                AddAttributes(name, givenAttributes, selectedNameAttributes);

                DeleteAttributes(name, givenAttributes, selectedNameAttributes);

                _dbContext.SaveChanges();

                _crmValidator.ValidateMinAndMaxAttributeLimit(name, availableSelectionTypes);

                tx.Complete();

                return crmAttributes.NameAttributes.Count != givenAttributes.Count
                    ? Request.CreateResponse(HttpStatusCode.OK, "Some attributes could not be updated.")
                    : Request.CreateResponse(HttpStatusCode.OK);
            }
        }

        void AddAttributes(Name name, IEnumerable<SelectedAttribute> givenAttributes,
            IEnumerable<SelectedAttribute> selectedNameAttributes)
        {
            foreach (
                var newAttribute in
                    givenAttributes.Where(
                        request => selectedNameAttributes.All(att => att.AttributeId != request.AttributeId)))
            {
                _crmValidator.ValidateTaskSecurity(ApplicationTask.MaintainNameAttributes,
                    ApplicationTaskAccessLevel.Create);

                if (!_crmValidator.ValidateAttribute(newAttribute))
                    HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.AttributeNotFound.ToString());

                var attributeToBeAdded =
                    new TableAttributes(KnownTableAttributes.Name,
                        name.Id.ToString(CultureInfo.InvariantCulture))
                    {
                        SourceTableId = newAttribute.AttributeTypeId,
                        TableCodeId = newAttribute.AttributeId
                    };
                _dbContext.Set<TableAttributes>().Add(attributeToBeAdded);
            }
        }

        void DeleteAttributes(Name name, IEnumerable<SelectedAttribute> givenAttributes,
            IEnumerable<SelectedAttribute> selectedNameAttributes)
        {
            var nameKey = name.Id.ToString(CultureInfo.InvariantCulture);
            foreach (
                var attributeToBeDeleted in
                    selectedNameAttributes.Where(na => givenAttributes.All(ap => ap.AttributeId != na.AttributeId))
                        .Select(attribute => _dbContext.Set<TableAttributes>()
                            .FirstOrDefault(ta => ta.ParentTable == KnownTableAttributes.Name
                                                  && ta.GenericKey == nameKey
                                                  && ta.TableCodeId == attribute.AttributeId))
                        .Where(attributeToBeDeleted => attributeToBeDeleted != null))
            {
                _crmValidator.ValidateTaskSecurity(ApplicationTask.MaintainNameAttributes,
                    ApplicationTaskAccessLevel.Delete);

                _dbContext.Set<TableAttributes>().Remove(attributeToBeDeleted);
            }
        }

        [HttpGet]
        [Route("activitysupport")]
        public ActivitySupportResponse ActivitySupport()
        {
            var requiredTableTypes = new[]
                                     {
                                         (int) TableTypes.ContactActivityType,
                                         (int) TableTypes.ContactActivityCategory
                                     };
            var selectionAvailable =
                _dbContext.Set<TableCode>().Where(tc => requiredTableTypes.Contains(tc.TableTypeId)).ToArray();

            return new ActivitySupportResponse
                   {
                       ActivityCategories = selectionAvailable.For(TableTypes.ContactActivityCategory)
                           .Select(s => new ActivityCategory
                                        {
                                            ActivityCategoryDescription = s.Name,
                                            ActivityCategoryId = s.Id
                                        }).ToList(),
                       ActivityTypes = ActivityTypeData(selectionAvailable),
                       CallStatus = KnownCallStatus.GetValues().Select(x => new CallStatusType
                                                                            {
                                                                                CallStatusDescription = x.Value,
                                                                                CallStatusId = x.Key
                                                                            }).ToList()
                   };
        }

        static List<ActivityTypeData> ActivityTypeData(IEnumerable<TableCode> selectionAvailable)
        {
            var required = new[]
                           {
                               KnownActivityTypes.PhoneCall,
                               KnownActivityTypes.Correspondence,
                               KnownActivityTypes.Email,
                               KnownActivityTypes.Facsimile
                           };

            var tableCodes = selectionAvailable as TableCode[] ?? selectionAvailable.ToArray();
            var all = tableCodes.ToArray().For(TableTypes.ContactActivityType)
                .Select(s => new ActivityTypeData
                             {
                                 ActivityTypeDescription =
                                     required.Contains(s.Id) ? string.Format("{0} (Incoming)", s.Name) : s.Name,
                                 ActivityTypeId = s.Id,
                                 IsOutgoing = false
                             });

            var outgoing = tableCodes.ToArray().For(TableTypes.ContactActivityType)
                .Where(x => required.Contains(x.Id))
                .Select(s => new ActivityTypeData
                             {
                                 ActivityTypeDescription = string.Format("{0} (Outgoing)", s.Name),
                                 ActivityTypeId = s.Id,
                                 IsOutgoing = true
                             });

            return all.Union(outgoing).ToList();
        }

        [HttpPost]
        [Route("case/{caseId}/contact")]
        [HandleNullArgument]
        public async Task<HttpResponseMessage> CreateNewContact(int caseId, Contact contact, bool overrideDuplicateCheck = false)
        {
            _crmValidator.ValidateTaskSecurity(ApplicationTask.MaintainName,
                ApplicationTaskAccessLevel.Create);

            var @case = _dbContext.Set<InprotechKaizen.Model.Cases.Case>().SingleOrDefault(c => c.Id.Equals(caseId));
            if (@case == null) HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.CaseDoesntExist.ToString());

            _crmValidator.ValidateCrmCaseSecurity(@case);

            contact.Surname = !string.IsNullOrEmpty(contact.Surname) ? contact.Surname : contact.DisplayName;
            contact.GivenName = !string.IsNullOrEmpty(contact.Surname) ? contact.GivenName : null;

            if (String.IsNullOrEmpty(contact.Surname))
                HttpResponseExceptionHelper.RaiseBadRequest(ErrorTypeCode.InvalidParameter.ToString());

            var r = await _caseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Update);
            if (r.IsUnauthorized)
                HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.NoRowaccessForCase.ToString());

            if (!_nameAccessSecurity.CanInsert())
                HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.NoRowaccessForName.ToString());

            if (!overrideDuplicateCheck)
            {
                var duplicates =
                    _nameValidator.CheckDuplicates(true, false, false, contact.GivenName, contact.Surname).ToList();
                if (duplicates.Any())
                {
                    return Request.CreateResponse(HttpStatusCode.Conflict, duplicates);
                }
            }

            var name = _crmContactProcessor.CreateContactName(contact);

            AddCaseName(@case, name, false);

            return new HttpResponseMessage(HttpStatusCode.OK);
        }

        [HttpPost]
        [Route("contact/{nameId}/contactActivity")]
        [HandleNullArgument]
        [RequiresAccessTo(ApplicationTask.MaintainContactActivity, ApplicationTaskAccessLevel.Create)]
        public HttpResponseMessage AddContactActivity(int nameId, ContactActivityRequest contactActivityRequest)
        {
            _activityProcessor.AddContactActivity(nameId, contactActivityRequest);

            return Request.CreateResponse(HttpStatusCode.OK);
        }
    }
}