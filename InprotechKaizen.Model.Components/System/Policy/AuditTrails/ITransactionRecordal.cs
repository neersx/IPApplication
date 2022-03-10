using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.System.Policy.AuditTrails
{
    public interface ITransactionRecordal
    {
        int RecordTransactionForName(int nameId, NameTransactionMessageIdentifier transactionMessage);

        int RecordTransactionForCase(int caseId, CaseTransactionMessageIdentifier transactionMessage, int? reasonNo = null, string component = null);

        int RecordTransactionFor(Case @case, CaseTransactionMessageIdentifier transactionMessage, int? reasonNo = null, int? componentId = null);

        int RecordTransactionFor(Name name, NameTransactionMessageIdentifier transactionMessage);

        int ExecuteTransactionFor(User user, Name name, NameTransactionMessageIdentifier transactionMessage);
    }
}