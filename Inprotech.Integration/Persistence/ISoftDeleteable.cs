using System;

namespace Inprotech.Integration.Persistence
{
    public interface ISoftDeleteable
    {
        bool IsDeleted { get; }
        DateTime? DeletedOn { get; }
        int? DeletedBy { get; }
    }
}