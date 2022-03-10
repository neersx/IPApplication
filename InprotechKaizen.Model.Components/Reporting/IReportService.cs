using System.Threading.Tasks;

namespace InprotechKaizen.Model.Components.Reporting
{
    public interface IReportService
    {
        Task<bool> Render(ReportRequest request);
    }
}