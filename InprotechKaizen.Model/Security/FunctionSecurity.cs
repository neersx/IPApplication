using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Security
{
    [Table("FUNCTIONSECURITY")]
    public class FunctionSecurity
    {
        [Key]
        [Column("FUNCTIONTYPE", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short FunctionTypeId { get; set; }

        [Key]
        [Column("SEQUENCENO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short SequenceNo { get; set; }

        [Column("OWNERNO")]
        public int? OwnerId { get; set; }

        [Column("ACCESSSTAFFNO")]
        public int? AccessStaffId { get; set; }

        [Column("ACCESSGROUP")]
        public short? AccessGroup { get; set; }

        [Column("ACCESSPRIVILEGES")]
        public short AccessPrivileges { get; set; }

        public bool CanRead => (AccessPrivileges & (short)FunctionSecurityPrivilege.CanRead) == (short)FunctionSecurityPrivilege.CanRead;
        public bool CanInsert => (AccessPrivileges & (short)FunctionSecurityPrivilege.CanInsert) == (short)FunctionSecurityPrivilege.CanInsert;
        public bool CanUpdate => (AccessPrivileges & (short)FunctionSecurityPrivilege.CanUpdate) == (short)FunctionSecurityPrivilege.CanUpdate;
        public bool CanDelete => (AccessPrivileges & (short)FunctionSecurityPrivilege.CanDelete) == (short)FunctionSecurityPrivilege.CanDelete;
        public bool CanPost => (AccessPrivileges & (short)FunctionSecurityPrivilege.CanPost) == (short)FunctionSecurityPrivilege.CanPost;
        public bool CanFinalise => (AccessPrivileges & (short)FunctionSecurityPrivilege.CanFinalise) == (short)FunctionSecurityPrivilege.CanFinalise;
        public bool CanReverse => (AccessPrivileges & (short)FunctionSecurityPrivilege.CanReverse) == (short)FunctionSecurityPrivilege.CanReverse;
        public bool CanCredit => (AccessPrivileges & (short)FunctionSecurityPrivilege.CanCredit) == (short)FunctionSecurityPrivilege.CanCredit;
        public bool CanAdjustValue => (AccessPrivileges & (short)FunctionSecurityPrivilege.CanAdjustValue) == (short)FunctionSecurityPrivilege.CanAdjustValue;
        public bool CanConvert => (AccessPrivileges & (short)FunctionSecurityPrivilege.CanConvert) == (short)FunctionSecurityPrivilege.CanConvert;

    }

    public enum FunctionSecurityPrivilege : short
    {
        None = 0,
        CanRead = 1,
        CanInsert = 2,
        CanUpdate = 4,
        CanDelete = 8,
        CanPost = 16,
        CanFinalise = 32,
        CanReverse = 64,
        CanCredit = 128,
        CanAdjustValue = 256,
        CanConvert = 512
    }
}