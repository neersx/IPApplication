using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.ExternalApplications.Crm
{
    public interface ICrmValidator
    {
        bool ValidateAttribute(SelectedAttribute attribute);

        void ValidateTaskSecurity(ApplicationTask task, ApplicationTaskAccessLevel level);

        void ValidateCrmCaseSecurity(InprotechKaizen.Model.Cases.Case @case);

        bool IsCrmName(Name name);

        void ValidateMinAndMaxAttributeLimit(Name name, ICollection<SelectionTypes> availableSelectionTypes);
    }

    public class CrmValidator : ICrmValidator
    {
        readonly IDbContext _dbContext;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public CrmValidator(IDbContext dbContext, ITaskSecurityProvider taskSecurityProvider)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (taskSecurityProvider == null) throw new ArgumentNullException("taskSecurityProvider");

            _dbContext = dbContext;
            _taskSecurityProvider = taskSecurityProvider;
        }

        public bool ValidateAttribute(SelectedAttribute attribute)
        {
            return
                _dbContext.Set<TableCode>()
                    .Any(tc => tc.Id == attribute.AttributeId && tc.TableTypeId == attribute.AttributeTypeId)
                ||
                _dbContext.Set<Office>()
                    .Any(
                        ofc => ofc.Id == attribute.AttributeId && attribute.AttributeTypeId == (short) TableTypes.Office);
        }

        public void ValidateTaskSecurity(ApplicationTask task, ApplicationTaskAccessLevel level)
        {
            if (!_taskSecurityProvider.HasAccessTo(task, level))
                HttpResponseExceptionHelper.RaiseForbidden(ErrorTypeCode.PermissionDenied.ToString());
        }

        public void ValidateCrmCaseSecurity(InprotechKaizen.Model.Cases.Case @case)
        {
            var propertyTypeId = @case.PropertyType.Code;

            if(propertyTypeId.Equals(_dbContext.Set<SiteControl>().First(sc => sc.ControlId == SiteControls.PropertyTypeCampaign).StringValue) || 
                propertyTypeId.Equals(_dbContext.Set<SiteControl>().First(sc => sc.ControlId == SiteControls.PropertyTypeMarketingEvent).StringValue))
                ValidateTaskSecurity(ApplicationTask.MaintainMarketingActivities,ApplicationTaskAccessLevel.Modify);
            else if(propertyTypeId.Equals(_dbContext.Set<SiteControl>().First(sc => sc.ControlId == SiteControls.PropertyTypeOpportunity).StringValue))
                ValidateTaskSecurity(ApplicationTask.MaintainOpportunity, ApplicationTaskAccessLevel.Modify);
            else
                HttpResponseExceptionHelper.RaiseForbidden(ErrorTypeCode.PermissionDenied.ToString());
        }

        public bool IsCrmName(Name name)
        {
            return name.NameTypeClassifications.Any(nc => nc.NameType.AllowCrmNames && nc.IsAllowed == 1);
        }

        public void ValidateMinAndMaxAttributeLimit(Name name, ICollection<SelectionTypes> availableSelectionTypes)
        {
            var errorCollection = new List<AttributeTypeErrorDetail>();

            foreach (var availableSelectionType in availableSelectionTypes)
            {
                var attributesCount = NameAttributesCount(name.Id, availableSelectionType.TableTypeId);
                if (availableSelectionType.MaximumAllowed < attributesCount)
                {
                    errorCollection.Add(new AttributeTypeErrorDetail
                    {
                        IsMaxLimitCrossed = true,
                        AttributeTypeId = availableSelectionType.TableTypeId
                    });
                }

                if (availableSelectionType.MinimumAllowed > attributesCount)
                {
                    errorCollection.Add(new AttributeTypeErrorDetail
                    {
                        IsMinLimitCrossed = true,
                        AttributeTypeId = availableSelectionType.TableTypeId
                    });
                }
            }

            if (!errorCollection.Any()) return;

            var attributesThatCrossedLimit = errorCollection.Select(ec => ec.AttributeTypeId).Distinct();

            var error = string.Format("Minimum or maximum number of values not fulfilled for attribute(s): {0}",
                string.Join(",", attributesThatCrossedLimit));

            HttpResponseExceptionHelper.RaiseNotAcceptable(error);
        }

        int NameAttributesCount(int nameId, short? attributeType)
        {
            var nameKey = nameId.ToString(CultureInfo.InvariantCulture);
            return _dbContext.Set<TableAttributes>().Count(
                ta =>
                    ta.GenericKey == nameKey && ta.ParentTable == KnownTableAttributes.Name &&
                    ta.SourceTableId == attributeType);
        }
    }
}