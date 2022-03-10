using System;
using System.Collections.Generic;
using Inprotech.Web.Cases.Details;

namespace Inprotech.Web.Cases.AssignmentRecordal
{
    
    public class RecordalRequest
    {
        public int CaseId { get; set; }
        public List<string> SelectedRowKeys { get; set; }
        public List<string> DeSelectedRowKeys { get; set; }
        public bool IsAllSelected { get; set; }
        public RecordalRequestType RequestType { get; set; }
        public AffectedCasesFilterModel Filter { get; set; } 
    }

    public class SaveRecordalRequest
    {
        public int CaseId { get; set; }
        public IEnumerable<int> SeqIds { get; set; }
        public DateTime RequestedDate { get; set; }
        public RecordalRequestType RequestType { get; set; }
    }

    public enum RecordalRequestType
    {
        Request,
        Apply,
        Reject
    }

    public class RecordalRequestData
    {
        public int SequenceNo { get; set; }
        public int? CaseId { get; set; }
        public string CaseReference { get; set; }
        public string CountryCode { get; set; }
        public string Country { get; set; }
        public string OfficialNo { get; set; }
        public int RecordalTypeNo { get; set; }
        public int StepId { get; set; }
        public string RecordalType { get; set; }
        public string Status { get; set; }
        public DateTime? RequestDate { get; set; }
        public DateTime? RecordDate { get; set; }
        public bool IsEditable { get; set; }
    }
}
