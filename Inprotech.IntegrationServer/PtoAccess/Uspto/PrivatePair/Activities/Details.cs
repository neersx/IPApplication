using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Persistence;
using Inprotech.IntegrationServer.PtoAccess.DmsIntegration;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities.CpaXml;
using Inprotech.IntegrationServer.PtoAccess.WorkflowIntegration;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public interface IDetailsWorkflow
    {
        Task<Activity> ConvertNotifyAndSendDocsToDms(Session session, ApplicationDownload applicationDownload);
    }

    public class DetailsWorkflow : IDetailsWorkflow
    {
        readonly IRepository _repository;
        readonly ICorrelationIdUpdator _correlationIdUpdator;
        readonly Func<DateTime> _now;
        readonly IBuildDmsIntegrationWorkflows _dmsWorkflowBuilder;

        public DetailsWorkflow(IRepository repository, ICorrelationIdUpdator correlationIdUpdator, Func<DateTime> now,
                               IBuildDmsIntegrationWorkflows dmsWorkflowBuilder)
        {
            _repository = repository;
            _correlationIdUpdator = correlationIdUpdator;
            _now = now;
            _dmsWorkflowBuilder = dmsWorkflowBuilder;
        }

        public async Task<Activity> ConvertNotifyAndSendDocsToDms(Session session, ApplicationDownload applicationDownload)
        {
            if (session == null) throw new ArgumentNullException(nameof(session));
            if (applicationDownload == null) throw new ArgumentNullException(nameof(applicationDownload));

            await EnsureCaseAvailable(applicationDownload.Number);

            var handleError = Activity.Run<IApplicationDownloadFailed>(_ => _.SaveArtifactAndNotify(applicationDownload));
            
            var convertWorkflow = BuildWorkflow(applicationDownload).ToArray();

            return Activity.Sequence(convertWorkflow)
                           .AnyFailed(handleError);
        }

        IEnumerable<Activity> BuildWorkflow(ApplicationDownload applicationDownload)
        {
            var convertToCpaXml = Activity.Run<IConvertApplicationDetailsToCpaXml>(c => c.Convert(applicationDownload));
            var workflowAutomation = Activity.Run<DocumentEvents>(de => de.UpdateFromPrivatePair(applicationDownload));

            var sendNotification = Activity.Run<NewCaseDetailsAvailableNotification>(a => a.Send(applicationDownload));

            var dmsAutomation = _dmsWorkflowBuilder.BuildPrivatePair(applicationDownload);

            var recheckCaseValidity = Activity.Run<ICheckCaseValidity>(c => c.IsValid(applicationDownload.Number));

            yield return convertToCpaXml;

            yield return workflowAutomation;

            yield return sendNotification;

            yield return dmsAutomation;

            yield return recheckCaseValidity;
        }

        async Task EnsureCaseAvailable(string applicationNumber)
        {
            var cases = _repository.Set<Case>();
            var @case = cases.SingleOrDefault(n => n.Source == DataSourceType.UsptoPrivatePair &&
                                                   n.ApplicationNumber == applicationNumber) ??
                        cases.Add(
                                  new Case
                                  {
                                      ApplicationNumber = applicationNumber,
                                      Source = DataSourceType.UsptoPrivatePair,
                                      CreatedOn = _now(),
                                      UpdatedOn = _now()
                                  });
            await _repository.SaveChangesAsync();
            _correlationIdUpdator.UpdateIfRequired(@case);
        }
    }
}