using System.Threading.Tasks;

namespace Inprotech.Integration.Jobs
{
    public interface IPersistJobState
    {
        Task<T> Load<T>(long jobExecutionId) where T : class;

        Task Save<T>(long jobExecutionId, T value) where T : class;
    }
}