import javax.swing.table.DefaultTableModel;
import java.util.*;


public class MyDefaultTableModel extends DefaultTableModel {
    public List<Boolean> editable = new ArrayList<Boolean>();
    public List<Class> classes = new ArrayList<Class>();
    
    public MyDefaultTableModel(int r, int c) {
        super(r,c);
        for (int i = 0; i < c; i++) {
            this.editable.add(false);
            this.classes.add(Object.class);
        }
    }
    
    public void removeColumn(int column) {
        columnIdentifiers.remove(column);
        for (Object row: dataVector) {
            ((Vector) row).remove(column);
        }
        this.editable.remove(column);
        this.classes.remove(column);
        fireTableStructureChanged();
    }
    
    @Override
    public boolean isCellEditable(int row, int column) {
        if(column < this.editable.size()) {
            return (boolean)this.editable.get(column);
        } else {
            return false;
        }
    }
    
    public void setColumnEditable(int column, boolean state) {
        if(column < this.editable.size()) {
            this.editable.set(column, (Boolean)state);
        } else {
            this.editable.add(column, (Boolean)state);
        }
    }
    
    @Override
    public Class getColumnClass(int column) {
        if(column < this.classes.size()) {
            return this.classes.get(column);
        } else {
            return Object.class;
        }
    }
    
    public void setColumnClass(int column, Class cls) {
        if(column < this.classes. size()) {
            this.classes.set(column, cls);
        } else {
            this.classes.add(column, cls);
        }
    }

/*     @Override
    public void addColumn(int idx) {
        super(idx)
        this.editable.add(idx, false);
        this.classes.add(idx, Object.class);
    }
    
    @Override
    public void removeColumn(int idx) {
        super(idx)
        this.editable.remove(idx);
        this.classes.remove(idx);
    } */
}