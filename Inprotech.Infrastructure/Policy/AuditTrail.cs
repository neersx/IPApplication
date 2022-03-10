namespace Inprotech.Infrastructure.Policy
{
    public interface IAuditTrail
    {
        void Start(int? componentId = null);
    }
}
