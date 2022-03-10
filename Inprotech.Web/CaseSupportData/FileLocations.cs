using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Cases.Maintenance;
using Inprotech.Web.Cases.Maintenance.Models;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.CaseSupportData
{
    public interface IFileLocations
    {
        IEnumerable<FileLocationsData> GetCaseFileLocations(int caseKey, int? filePartId, bool showHistory = false, bool fileHistoryFromMaintenance = false);
        IEnumerable<CodeDescription> AllowableFilters(int caseKey, string field, CommonQueryParameters parameters);
        IEnumerable<ValidationError> ValidateFileLocations(Case @case, FileLocationsData currentRow, IEnumerable<FileLocationsData> changedRows);
        IEnumerable<ValidationError> ValidateFileLocationsOnSave(Case @case, FileLocationsData currentRow, IEnumerable<FileLocationsData> changedRows);
        IEnumerable<ValidationError> ValidateFileLocations(int caseKey, FileLocationsData currentRow, IEnumerable<FileLocationsData> changedRows);
        string GetCaseReference(int caseId);
    }

    public class FileLocations : IFileLocations
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCulture;

        public FileLocations(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCulture = preferredCultureResolver;
        }

        public IEnumerable<FileLocationsData> GetCaseFileLocations(int caseId, int? filePartId, bool showHistory, bool fileHistoryFromMaintenance)
        {
            var culture = _preferredCulture.Resolve();
            var caseLocations = _dbContext.Set<CaseLocation>().Where(_ => _.CaseId == caseId);
            var fileParts = _dbContext.Set<CaseFilePart>().Where(_ => _.CaseId == caseId);

            var interimResults = (from cl in caseLocations
                                  join fp in fileParts on new { a = cl.FilePartId.Value, cl.CaseId } equals new { a = fp.FilePart, fp.CaseId } into filePartDetails
                                  from fpd in filePartDetails.DefaultIfEmpty()
                                  select new
                                  {
                                      cl,
                                      fpd,
                                      fld = DbFuncs.GetTranslation(cl.FileLocation.Name, null, cl.FileLocation.NameTId, culture)
                                  }).ToArray();

            var results = interimResults.Select(_ => new FileLocationsData
            {
                Id = _.cl.Id,
                BarCode = _.cl.FileLocation.UserCode ?? string.Empty,
                BayNo = _.cl.BayNo,
                FileLocation = _.fld,
                FileLocationId = _.cl.FileLocationId,
                FilePart = _.fpd?.FilePartTitle,
                FilePartId = _.cl.FilePartId,
                IssuedBy = _.cl.Name?.FormattedWithDefaultStyle(),
                IssuedById = _.cl.Name?.Id,
                WhenMoved = _.cl.WhenMoved,
                RowKey = _.cl.Id.ToString()
            });

            if (fileHistoryFromMaintenance)
            {
                return results.Where(_ => _.FilePartId == filePartId).GroupBy(_ => _.FilePartId).Select(_ => _.OrderByDescending(x => x.WhenMoved).Take(1)).SelectMany(s => s);
            }

            if (!showHistory)
            {
                results = results.GroupBy(_ => _.FilePartId).Select(_ => _.OrderByDescending(x => x.WhenMoved).Take(1)).SelectMany(s => s);
            }

            return results.OrderByDescending(_ => _.WhenMoved);
        }

        public string GetCaseReference(int caseKey)
        {
            return _dbContext.Set<Case>().Single(x => x.Id == caseKey).Irn;
        }

        public IEnumerable<CodeDescription> AllowableFilters(int caseKey, string field, CommonQueryParameters parameters)
        {
            if (parameters == null) throw new ArgumentNullException("parameters");
            IEnumerable<CodeDescription> result;
            var data = GetCaseFileLocations(caseKey, null, true, false);
            if (field == "filePart")
            {
                result = data.Select(_ => new CodeDescription()
                {
                    Code = _.FilePart ?? string.Empty,
                    Description = _.FilePart ?? string.Empty
                });
            }
            else
            {
                result = data.Select(_ => new CodeDescription()
                {
                    Code = _.FileLocation ?? string.Empty,
                    Description = _.FileLocation ?? string.Empty
                });
            }
            return result.DistinctBy(x => x.Code)
                         .OrderBy(x => x.Description);
        }

        public IEnumerable<ValidationError> ValidateFileLocations(int caseKey, FileLocationsData currentRow, IEnumerable<FileLocationsData> changedRows)
        {
            var @case = _dbContext.Set<Case>().Single(x => x.Id == caseKey);
            return ValidateFileLocations(@case, currentRow, changedRows);
        }

        public IEnumerable<ValidationError> ValidateFileLocations(Case @case, FileLocationsData currentRow, IEnumerable<FileLocationsData> changedRows)
        {
            var alreadyAddedFileLocations = GetAlreadyAddedLocations(@case, currentRow, changedRows);

            var duplicateLocation = false;
            if (alreadyAddedFileLocations.Any(_ => _.Key == currentRow.FileLocationId
                                                   && _.FilePartKey == currentRow.FilePartId && _.WhenMoved == currentRow.WhenMoved))
            {
                duplicateLocation = true;
                yield return ValidationErrors.SetCustomError(KnownCaseMaintenanceTopics.FileLocations, FileLocationsInputNames.FileLocation,
                                                             "field.errors.duplicateFileLocations", null, true, currentRow.RowKey);
            }

            var activeFileRequest = @case.FileRequests.Where(_ => _.FileLocationId != currentRow.FileLocationId
                                                            && _.DateRequired <= currentRow.WhenMoved && _.FilePartId == currentRow.FilePartId && _.Status != 2).Take(1).ToArray();
            if (activeFileRequest.Any() && !duplicateLocation)
            {
                var dateRequired = activeFileRequest.First().DateRequired;
                if (dateRequired != null)
                {
                    yield return ValidationErrors.SetCustomError(KnownCaseMaintenanceTopics.FileLocations, FileLocationsInputNames.ActiveFileRequest,
                                                                 "field.errors.activeFileRequestExist", dateRequired.Value.ToString("dd-MMM-yyyy"),
                                                                 true, currentRow.RowKey);
                }
            }
        }

        public IEnumerable<ValidationError> ValidateFileLocationsOnSave(Case @case, FileLocationsData currentRow, IEnumerable<FileLocationsData> changedRows)
        {
            var alreadyAddedFileLocations = GetAlreadyAddedLocations(@case, currentRow, changedRows);

            if (alreadyAddedFileLocations.Any(_ => _.Key == currentRow.FileLocationId
                                                   && _.FilePartKey == currentRow.FilePartId && _.WhenMoved == currentRow.WhenMoved))
            {
                yield return ValidationErrors.SetCustomError(KnownCaseMaintenanceTopics.FileLocations, FileLocationsInputNames.FileLocation,
                                                             "field.errors.duplicateFileLocations", null, true, currentRow.RowKey);
            }
        }

        private List<Validation> GetAlreadyAddedLocations(Case @case, FileLocationsData currentRow, IEnumerable<FileLocationsData> changedRows)
        {
            var otherRows = changedRows.Where(x => x.RowKey != currentRow.RowKey).ToList();
            var rowsOtherThanDeleted = otherRows.Where(_ => _.Status != KnownModifyStatus.Delete).ToList();
            var alreadyAddedFileLocations = @case.CaseLocations.Where(_ => _.Id != int.Parse(currentRow.RowKey)
                                                                           && otherRows.All(y => y.Id != _.Id))
                                                 .Select(row => new Validation() { Key = row.FileLocation.Id, FilePartKey = row.FilePartId, WhenMoved = row.WhenMoved }).ToList();
            alreadyAddedFileLocations.AddRange(rowsOtherThanDeleted.Select(row => new Validation() { Key = row.FileLocationId, FilePartKey = row.FilePartId, WhenMoved = row.WhenMoved }));
            return alreadyAddedFileLocations;
        }
    }

    public class Validation
    {
        public int Key { get; set; }
        public short? FilePartKey { get; set; }
        public DateTime WhenMoved { get; set; }
    }

    public class FileLocationsData
    {
        public int Id { get; set; }
        public int FileLocationId { get; set; }
        public string FileLocation { get; set; }
        public DateTime WhenMoved { get; set; }
        public short? FilePartId { get; set; }
        public string FilePart { get; set; }
        public string IssuedBy { get; set; }
        public int? IssuedById { get; set; }
        public string BayNo { get; set; }
        public string BarCode { get; set; }
        public string Status { get; set; }
        public string RowKey { get; set; }
    }
}
