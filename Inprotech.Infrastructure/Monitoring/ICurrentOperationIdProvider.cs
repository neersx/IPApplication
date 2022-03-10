namespace Inprotech.Infrastructure.Monitoring
{
    public interface ICurrentOperationIdProvider
    {
       string OperationId { get; }
    }
}
