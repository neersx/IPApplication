using System.Linq;

namespace Inprotech.Infrastructure.Security
{
    public interface ISubjectSecurityProvider
    {
        bool HasAccessToSubject(ApplicationSubject subject);
        IQueryable<SubjectAccess> AvailableSubjectsFromDb();
    }
}
