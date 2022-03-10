using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Security
{
    [Table("PROGRAM")]
    public class Program
    {

        [Key]
        [MaxLength(8)]
        [Column("PROGRAMID")]
        public string Id { get; internal set; }

        [MaxLength(50)]
        [Column("PROGRAMNAME")]
        public string Name { get; internal set; }

        [Column("PROGRAMNAME_TID")]
        public int? Name_TID { get; internal set; }

        [MaxLength(1)]
        [Column("PROGRAMGROUP")]
        public string ProgramGroup { get; internal set; }

        [MaxLength(8)]
        [Column("PARENTPROGRAM")]
        [ForeignKey("ParentProgram")]
        public string ParentProgramId { get; internal set; }

        public Program(string id, string name, string programGroup = null, Program parentProgram = null)
        {
            Id = id;
            Name = name;
            ParentProgram = parentProgram;
            ProgramGroup = programGroup;
        }

        public Program()
        {
        }

        public Program ParentProgram { get; protected set; }

    }
}
