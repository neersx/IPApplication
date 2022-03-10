using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Web.Cases.Maintenance.Models;
using Inprotech.Web.Maintenance.Topics;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Cases.Maintenance.Updaters
{
    public class FileLocationsTopicUpdater : ITopicDataUpdater<Case>
    {
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControls;

        public FileLocationsTopicUpdater(ISiteControlReader siteControls, IDbContext dbContext)
        {
            _siteControls = siteControls;
            _dbContext = dbContext;
        }

        public void UpdateData(JObject topicData, MaintenanceSaveModel model, Case @case)
        {
            var topic = topicData.ToObject<FileLocationsSaveModel>();
            int i = 0;
            foreach (var e in topic.Rows.OrderBy(_ => _.Status == KnownModifyStatus.Delete))
            {
                var editedFileLocation = @case.CaseLocations.SingleOrDefault(x => x.Id == int.Parse(e.RowKey));
                if (e.Status == KnownModifyStatus.Delete)
                {
                    if (editedFileLocation != null)
                    {
                        _dbContext.Set<CaseLocation>().Remove(editedFileLocation);
                    }

                    continue;
                }

                if (editedFileLocation == null)
                {
                    if (e.FileLocationId > 0)
                    {
                        var existingFileLocationsWithSameTime = @case.CaseLocations.Any(x => x.WhenMoved.Equals(e.WhenMoved));
                        var hasSameTime = topic.Rows.Except(new[] { e }).Any(x => x.WhenMoved.Equals(e.WhenMoved));
                        e.WhenMoved = hasSameTime || existingFileLocationsWithSameTime ? e.WhenMoved.AddSeconds(++i).AddMilliseconds(DateTime.Now.Millisecond) : e.WhenMoved;
                        var location = _dbContext.Set<TableCode>().Single(tc => tc.Id == e.FileLocationId && tc.TableTypeId == (int) TableTypes.FileLocation);

                        editedFileLocation = new CaseLocation(@case, location, e.WhenMoved) {FilePartId = e.FilePartId, BayNo = e.BayNo, IssuedBy = e.IssuedById == 0 ? null : e.IssuedById};
                    }

                    @case.CaseLocations.Add(editedFileLocation);

                    var fileRequestHistory = _siteControls.Read<int>(SiteControls.MaintainFileRequestHistory);
                    var fileRequests = @case.FileRequests.Where(x => x.CaseId == @case.Id && x.FileLocationId == e.FileLocationId && x.FilePartId == e.FilePartId).ToList();

                    if (fileRequestHistory == 0)
                    {
                        foreach (var fileRequest in fileRequests) @case.FileRequests.Remove(fileRequest);
                    }
                    else
                    {
                        foreach (var fileRequest in fileRequests) fileRequest.Status = 2;
                    }
                }

                else
                {
                    editedFileLocation.FilePartId = e.FilePartId;
                    editedFileLocation.FileLocationId = e.FileLocationId;
                    editedFileLocation.BayNo = e.BayNo;
                    editedFileLocation.IssuedBy = e.IssuedById == 0 ? null : e.IssuedById;
                    if (editedFileLocation.FileLocation != null)
                    {
                        editedFileLocation.FileLocation.UserCode = e.BarCode;
                    }

                    editedFileLocation.WhenMoved = e.WhenMoved;
                }
            }
        }

        public void PostSaveData(JObject topicData, MaintenanceSaveModel model, Case @case)
        {
            var maxLocationsCount = _siteControls.Read<int>(SiteControls.MAXLOCATIONS);

            var caseLocationsCount = @case.CaseLocations.Count(_ => _.CaseId == @case.Id);

            if (caseLocationsCount > maxLocationsCount)
            {
                var recordsToRemove = caseLocationsCount - maxLocationsCount;
                var caseLocations = @case.CaseLocations.Where(_ => _.CaseId == @case.Id).OrderBy(_ => _.WhenMoved).Take(recordsToRemove);

                foreach (var caseLocation in caseLocations) _dbContext.Set<CaseLocation>().Remove(caseLocation);
            }
        }
    }
}