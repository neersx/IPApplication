using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("CASENAMEREQUESTCASES")]
    public class GlobalNameChangeRequest
    {
        [Obsolete("For persistence only.")]
        public GlobalNameChangeRequest()
        {
        }

        [Column("REQUESTNO")]
        public int RequestNo { get; set; }

        [Column("CASEID")]
        public int CaseId { get; set; }
    }
}