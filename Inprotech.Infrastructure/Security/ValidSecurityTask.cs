namespace Inprotech.Infrastructure.Security
{
    public class ValidSecurityTask
    {
        public ValidSecurityTask()
        {
        }

        public ValidSecurityTask(short taskId, bool canInsert, bool canUpdate, bool canDelete, bool canExecute)
        {
            TaskId = taskId;
            CanInsert = canInsert;
            CanUpdate = canUpdate;
            CanDelete = canDelete;
            CanExecute = canExecute;
        }

        public short TaskId { get; set; }

        public bool CanInsert { get; set; }

        public bool CanUpdate { get; set; }

        public bool CanDelete { get; set; }

        public bool CanExecute { get; set; }
    }

    public class SubjectAccess
    {
        public SubjectAccess()
        {
        }

        public SubjectAccess(short taskId, bool canSelect)
        {
            TopicId = taskId;
            CanSelect = canSelect;
        }

        public short TopicId { get; set; }

        public bool CanSelect { get; set; }
    }

    public class WebPartAccess
    {
        public WebPartAccess()
        {
        }

        public WebPartAccess(short webPartId, bool canSelect)
        {
            WebPartId = webPartId;
            CanSelect = canSelect;
        }

        public short WebPartId { get; set; }

        public bool CanSelect { get; set; }
    }
}