// src/native/engine/android/java/com/nativecr/RecyclerViewAdapter.java

package com.nativecr;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.recyclerview.widget.RecyclerView;

import java.util.ArrayList;
import java.util.List;

public class RecyclerViewAdapter extends RecyclerView.Adapter<RecyclerViewAdapter.ViewHolder> {
    private List<String> items = new ArrayList<>();
    private long nativePtr;

    public interface AdapterCallback {
        void onItemClick(int position);
        void onItemLongClick(int position);
        long onCreateViewHolder(int position);
        void onBindViewHolder(long viewPtr, int position);
    }

    private AdapterCallback callback;

    public RecyclerViewAdapter(long ptr) {
        this.nativePtr = ptr;
    }

    public void setCallback(AdapterCallback cb) {
        this.callback = cb;
    }

    public void setItems(List<String> items) {
        this.items = items;
        notifyDataSetChanged();
    }

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        long viewPtr = callback.onCreateViewHolder(viewType);
        View view = new View(parent.getContext());
        return new ViewHolder(view, viewPtr);
    }

    @Override
    public void onBindViewHolder(ViewHolder holder, int position) {
        callback.onBindViewHolder(holder.viewPtr, position);
    }

    @Override
    public int getItemCount() {
        return items.size();
    }

    public class ViewHolder extends RecyclerView.ViewHolder implements View.OnClickListener, View.OnLongClickListener {
        public long viewPtr;

        public ViewHolder(View itemView, long ptr) {
            super(itemView);
            this.viewPtr = ptr;
            itemView.setOnClickListener(this);
            itemView.setOnLongClickListener(this);
        }

        @Override
        public void onClick(View v) {
            if (callback != null) {
                callback.onItemClick(getAdapterPosition());
            }
        }

        @Override
        public boolean onLongClick(View v) {
            if (callback != null) {
                callback.onItemLongClick(getAdapterPosition());
            }
            return true;
        }
    }
}
