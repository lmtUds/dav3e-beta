import javax.swing.table.*;
import java.util.*;
import com.jidesoft.grid.*;


public class MySortableTableModel extends SortableTableModel {

    public MySortableTableModel(TableModel m) {
        super(m);
    }
    
    @Override
    public EditorContext getEditorContextAt(int row, int column) {
        if (this.getColumnClass(column) == boolean.class) {
            return BooleanCheckBoxCellEditor.CONTEXT;
        }
        return null;
    }
}