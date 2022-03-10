using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Security
{
    [Table("PROFILEPROGRAM")]
    public class ProfileProgram
    {
        public ProfileProgram() {}

        public ProfileProgram(int profileId, Program program)
        {
            ProfileId = profileId;
            Program = program;
            ProgramId = program.Id;
        }

        [Column("PROFILEID")]
        public int ProfileId { get; internal set; }

        [Required]
        [MaxLength(8)]
        [Column("PROGRAMID")]
        [ForeignKey("Program")]
        public string ProgramId { get; internal set; }

        public virtual Program Program { get; protected set; }
    }
}
