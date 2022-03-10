using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Cases.Maintenance;
using Inprotech.Web.Cases.Maintenance.Models;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using Case = InprotechKaizen.Model.Cases.Case;

namespace Inprotech.Web.CaseSupportData
{
    public interface IDesignElements
    {
        IEnumerable<DesignElementData> GetCaseDesignElements(int caseId);
        IEnumerable<ValidationError> ValidateDesignElements(int caseKey, DesignElementData currentRow, IEnumerable<DesignElementData> changedRows);
        IEnumerable<ValidationError> ValidateDesignElements(Case @case, DesignElementData currentRow, IEnumerable<DesignElementData> changedRows);
    }

    public class DesignElements : IDesignElements
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCulture;

        public DesignElements(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCulture = preferredCultureResolver;
        }

        public IEnumerable<DesignElementData> GetCaseDesignElements(int caseId)
        {
            var culture = _preferredCulture.Resolve();

            var images = _dbContext.Set<CaseImage>().Where(_ => _.CaseId == caseId && _.FirmElementId != null).ToArray();

            var result = _dbContext.Set<DesignElement>().Where(_ => _.CaseId == caseId)
                                   .Select(_ => new DesignElementData
                                   {
                                       FirmElementCaseRef = _.FirmElementId,
                                       ClientElementCaseRef = _.ClientElementId,
                                       ElementOfficialNo = _.OfficialElementId,
                                       RegistrationNo = _.RegistrationNo,
                                       ElementDescription = DbFuncs.GetTranslation(_.Description, null, _.ElementdescTid, culture),
                                       Renew = _.IsRenew,
                                       Sequence = _.Sequence,
                                       NoOfViews = _.Typeface,
                                       StopRenewDate = _.StopRenewDate,
                                       RowKey = _.Sequence.ToString()

                                   }).OrderBy(_ => _.FirmElementCaseRef).ToArray();

            foreach (var res in result)
            {
                res.Images = images.Where(_ => res.FirmElementCaseRef == _.FirmElementId).Select(_ => new ImageModel { Key = _.ImageId, Description = _.CaseImageDescription }).ToArray();
            }

            return result;
        }

        public IEnumerable<ValidationError> ValidateDesignElements(int caseKey, DesignElementData currentRow, IEnumerable<DesignElementData> changedRows)
        {
            var @case = _dbContext.Set<Case>().Single(x => x.Id == caseKey);
            return ValidateDesignElements(@case, currentRow, changedRows);
        }

        public IEnumerable<ValidationError> ValidateDesignElements(Case @case, DesignElementData currentRow, IEnumerable<DesignElementData> changedRows)
        {
            var otherRows = changedRows.Where(x => x.RowKey != currentRow.RowKey).ToList();
            var rowsOtherThanDeleted = otherRows.Where(_ => _.Status != KnownModifyStatus.Delete).ToList();

            var currentRowEntity = @case.CaseDesignElements.FirstOrDefault(x => x.Sequence == currentRow.Sequence);

            var alreadyAddedFirmElemRefs = @case.CaseDesignElements.Where(_ => _.Sequence != currentRow.Sequence
                                                                               && otherRows.All(y => y.Sequence != _.Sequence))
                                                .Select(row => row.FirmElementId.ToLower()).ToList();
            alreadyAddedFirmElemRefs.AddRange(rowsOtherThanDeleted.Select(row => row.FirmElementCaseRef.ToLower()));

            if (alreadyAddedFirmElemRefs.Contains(currentRow.FirmElementCaseRef.ToLower()))
            {
                yield return ValidationErrors.SetCustomError(KnownCaseMaintenanceTopics.DesignElements, DesignElementsInputNames.FirmElementId, "field.errors.duplicateDesignElement", null, true, currentRow.RowKey);
            }

            if (currentRow.Images == null || !currentRow.Images.Any()) yield break;

            var alreadyAddedImages = @case.CaseImages.Where(x => x.FirmElementId != null &&
                                                                 currentRowEntity?.FirmElementId != x.FirmElementId
                                                                 && otherRows.All(y => y.FirmElementCaseRef != x.FirmElementId))
                                          .Select(row => row.ImageId).ToList();
            alreadyAddedImages.AddRange(rowsOtherThanDeleted.Where(x => x.Images != null && x.Images.Any()).SelectMany(x => x.Images).Select(i => i.Key));

            var duplicateImages = (from img in currentRow.Images where alreadyAddedImages.Contains(img.Key) select img.Key).ToArray();
            if (duplicateImages.Any())
            {
                yield return ValidationErrors.SetCustomError(KnownCaseMaintenanceTopics.DesignElements, DesignElementsInputNames.ImageId, "field.errors.duplicateElementImage", duplicateImages, true, currentRow.RowKey);
            }
        }
    }

    public class DesignElementData
    {
        public string FirmElementCaseRef { get; set; }
        public string ClientElementCaseRef { get; set; }
        public string ElementOfficialNo { get; set; }
        public string RegistrationNo { get; set; }
        public int? NoOfViews { get; set; }
        public string ElementDescription { get; set; }
        public int? Sequence { get; set; }
        public bool? Renew { get; set; }
        public DateTime? StopRenewDate { get; set; }
        public IEnumerable<ImageModel> Images { get; set; }
        public string Status { get; set; }
        public string RowKey { get; set; }
    }
}
