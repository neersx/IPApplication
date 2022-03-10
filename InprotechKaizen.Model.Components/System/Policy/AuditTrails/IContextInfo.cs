namespace InprotechKaizen.Model.Components.System.Policy.AuditTrails
{
    public interface IContextInfo
    {
        void EnsureUserContext(int? userId = null, int? transactionInfoId = null, int? batchId = null, int? componentId = null);        
    }

    public interface IContextInfoSerializer
    {
        byte[] SerializeContextInfo(int userId, int? transactionInfoId = null, int? batchId = null, int? componentId = null);
    }
}